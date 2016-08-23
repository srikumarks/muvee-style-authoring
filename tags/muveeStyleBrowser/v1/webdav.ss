#lang scheme

(require [only-in html read-html-as-xml]
         [only-in xml xml->xexpr]
         net/url
         scheme/match
         scheme/date
         net/head)

(define *cache-dir* (path->directory-path (build-path (find-system-path 'pref-dir) "muveeStyles" "cache")))

(make-directory* *cache-dir*)

(define *cache-table-file* (build-path *cache-dir* "cache-table.scm"))

(define *url-cache* 
  (if (file-exists? *cache-table-file*)
      (call-with-input-file *cache-table-file* read)
      (make-immutable-hash '())))

(provide/contract [webdav-status parameter?])
(define webdav-status (make-parameter (lambda (str) #f)))
(define (status . etc)
  ((webdav-status) (apply format etc)))

(provide/contract [webdav-directory-list (url? . -> . (listof string?))])
(define (webdav-directory-list url)
  (let* ([response (call/input-url url get-pure-port read-html-as-xml)]
         [response-xexpr (xml->xexpr (first response))])
    
    (get-attributes 'href (filter-tag-path '(html body ul li a) (list response-xexpr)))))

(define *date-regexp* #px"[a-zA-Z]+, ([0-9]+) ([a-zA-Z]+) ([0-9]+) ([0-9]{2}):([0-9]{2}):([0-9]{2}) GMT")

(provide/contract [webdav-resource-modify-seconds (url? . -> . (or/c number? boolean?))])
(define (webdav-resource-modify-seconds url)
  (call/input-url url head-impure-port 
                  (lambda (p)
                    (let* ([headers (purify-port p)]
                           [mod-date-str (extract-field "Last-Modified" headers)])
                      (and mod-date-str
                           (match (regexp-match *date-regexp* mod-date-str)
                             [(list _ day month year h m s)
                              (find-seconds (string->number s) 
                                            (string->number m) 
                                            (string->number h) 
                                            (string->number day) 
                                            (month3->number month) 
                                            (string->number year))]
                             [_ #f]))))))
          
(provide/contract [webdav-directory-exists? (url? . -> . boolean?)])
(define (webdav-directory-exists? url)
  (if (regexp-match #px"/$" (url->string url)) #t #f))

(define (as-url url)
  (if (url? url) url (string->url url)))

(define (as-path path)
  (if (path? path) path (string->path path)))

(provide/contract [webdav-download-file (((or/c string? url?)
                                          (or/c string? path?))
                                         (#:use-cache boolean?)
                                         . ->* .
                                         any)])
                                        
(define (webdav-download-file url local-file #:use-cache [use-cache #f])
  (if (and (url? url) (path? local-file))
      (let ([cached-path (url->cache-path url)])
        (if (and use-cache (hash-ref *url-cache* (url->string url) #f))
            (copy-file/replace cached-path local-file)
            (begin
              (let-values ([(base name must-be-dir?) (split-path local-file)])
                (status "Downloading [~a] ..." (path->string name)))
              (call-with-output-file local-file
                (lambda (out)
                  (call/input-url url get-pure-port
                                  (lambda (in) (copy-port in out))))
                #:exists 'replace)
              (copy-file/replace local-file cached-path)
              (cache-url! url cached-path)
              local-file)))
      (webdav-download-file (as-url url) (as-path local-file))))

(provide/contract [webdav-download-folder (((or/c string? url?)
                                            (or/c string? path?))
                                           (#:use-cache boolean?)
                                           . ->* .
                                           any)])
(define (webdav-download-folder url local-dir #:use-cache [use-cache #f])
  (if (and (url? url) (path? local-dir))
      (begin (make-directory* local-dir)
             (for-each (lambda (f)
                         (with-handlers ([exn:fail? (lambda (e) (display e) #f)])
                           (match f
                             ["../" #f] ; Don't do anything
                             [(pregexp #px".+/$") ; This is a sub-folder. Do recursive download.
                              (webdav-download-folder (combine-url/relative url f) 
                                                      (build-path local-dir f) 
                                                      #:use-cache use-cache)]
                             [_ ; Some file. Download it.
                              (webdav-download-file (combine-url/relative url f) 
                                                    (build-path local-dir f) 
                                                    #:use-cache use-cache)])))
                       (webdav-directory-list url)))
      (webdav-download-folder (as-url url) 
                              (as-path local-dir) 
                              #:use-cache use-cache)))

(define styles (string->url "http://ekalavya.local/~kumar/musa/examples"))
(define musa (string->url "http://muvee-style-authoring.googlecode.com/svn/trunk/examples/"))

; (filter-tag-path '(html body ul li a) (list hx))
(define (filter-tag-path tag-path tree)
  (match tag-path
    ['() tree]
    [(list atag)
     (filter (match-lambda [(list-rest t _ _) (eq? t atag)]
                           [_ #f])
             tree)]
    [(cons atag child-tags)
     (filter-tag-path child-tags (apply append (map (lambda (x) (match x 
                                                                  [(list-rest t _ _)
                                                                   (if (eq? t atag)
                                                                       (rest (rest x))
                                                                       '())]
                                                                  [_ '()]))
                                                    tree)))]))

(define (get-attributes attr tree)
  (apply append (map (match-lambda
                       [(list-rest tag attrs body)
                        (let ([a (assoc attr attrs)])
                          (if a (rest a) '()))]
                       [_ '()])
                     tree)))

(define (month3->number month)
  (match month
    ["Jan" 1]
    ["Feb" 2]
    ["Mar" 3]
    ["Apr" 4]
    ["May" 5]
    ["Jun" 6]
    ["Jul" 7]
    ["Aug" 8]
    ["Sep" 9]
    ["Oct" 10]
    ["Nov" 11]
    ["Dec" 12]))

(define (copy-file/replace src dest)
  (when (file-exists? dest) (delete-file dest))
  (copy-file src dest)
  dest)

(define (cache-url! url file)
  (set! *url-cache* (hash-set *url-cache* (url->string url) (path->string file)))
  (call-with-output-file *cache-table-file* (lambda (p) (write *url-cache* p)) #:exists 'replace))
  
(define (url->cache-path url)
  (build-path *cache-dir* (number->string (equal-hash-code (url->string url)))))

(provide/contract [recursive-path-modify-seconds ((or/c string? path?) . -> . exact-integer?)])
(define (recursive-path-modify-seconds path)
  (let ([t (file-or-directory-modify-seconds path)])
    (if (file-exists? path)
        t
        (if (directory-exists? path)
            (parameterize ([current-directory path])
              (max t (apply max (map recursive-path-modify-seconds (directory-list path)))))
            0))))
