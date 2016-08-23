#lang scheme

(require (only-in scheme/gui 
                  get-resource
                  message-box)
         (only-in xml
                  read-xml
                  xml->xexpr
                  document-element))


(provide/contract [*version* (and/c number? positive?)])
(define *version* 1.6)
(define *compatible-version* 1.6)
(define *svn-version* 381)

(define (find-muvee-reveal-common-files-folder default-path)
  (let ([result (box default-path)])
    ; Look for the location of MVRT.dll using its CLSID and infer the 
    ; common files folder from its location.
    (if (get-resource "HKEY_LOCAL_MACHINE"
                      "SOFTWARE\\Classes\\CLSID\\{30A8E5D8-A4BD-4038-981E-AD2B7AD781EA}\\InprocServer32\\"
                      result)
        (path-only (unbox result))
        (path->directory-path (string->path (unbox result))))))
  
; (filter-tag-path '(html body ul li a) (list hx))
(provide/contract [filter-tag-path (-> list? list? list?)])
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

(provide/contract [get-attributes (-> symbol? list? list?)])
(define (get-attributes attr tree)
  (apply append (map (match-lambda
                       [(list-rest tag attrs body)
                        (let ([a (assoc attr attrs)])
                          (if a (rest a) '()))]
                       [_ '()])
                     tree)))


(provide/contract [*install-dir* path?])
(define *install-dir* 
  (let* [(candidate 
          (match (system-type 'os)
            ['windows (find-muvee-reveal-common-files-folder "C:\\Program Files\\Common Files\\muvee Technologies\\071203\\")]
            [_ (string->path "/tmp/installed-styles/")]))
         (mvrt.ini (build-path candidate "MVRT.ini"))]
    (if (file-exists? mvrt.ini)
        ; then -> Get the styles folder from mvrt.ini
        (let [(styles-folder
               (first (call-with-input-string
                       (third (first (filter-tag-path '(mvrtini enumfolders folder) 
                                                      (list (xml->xexpr (document-element (call-with-input-file mvrt.ini read-xml)))))))
                       port->lines)))]
          (path->directory-path (string->path styles-folder)))
        ; else -> Use the folder in which mvrt.dll is located.
        candidate)))
        
        

(when (not (directory-exists? *install-dir*))
  (message-box "Error" "Please install muvee Reveal first.\nhttp://www.muvee.com" #f '(ok))
  (exit))
           
(provide/contract [*config-dir* path?])
(define *config-dir* (let* ([pref (find-system-path 'pref-dir)])
                            (path->directory-path (build-path pref "muveeStyles"))))
                                 
(provide/contract [*warehouse-dir* path?])
(define *warehouse-dir* (path->directory-path (build-path *config-dir* "warehouse")))

(provide/contract [my-styles-folder path?])
(define my-styles-folder *install-dir*)

(provide/contract [config-file (string? . -> . path?)])
(define (config-file filename)
  (build-path *config-dir* filename))

(provide/contract [config-dir (string? . -> . path?)])
(define (config-dir dirname)
  (path->directory-path (build-path *config-dir* dirname)))

(define *config-file* (config-file "info.ss"))

(provide/contract [*cache-dir* path?])
(define *cache-dir* (path->directory-path (config-dir "cache")))

(define (prepare-fresh-setup)
  (when (directory-exists? *warehouse-dir*)
    (delete-directory/files *warehouse-dir*))
  (make-directory* *warehouse-dir*)
  (when (directory-exists? *cache-dir*)
    (delete-directory/files *cache-dir*))
  (make-directory* *cache-dir*)
  (when (not (directory-exists? my-styles-folder))
    (make-directory* my-styles-folder)))

(define *config-hash* (if (file-exists? *config-file*)
                        (let ([h (hash-copy (call-with-input-file *config-file* read))])
                          (if (< (hash-ref h 'version) *compatible-version*)
                              (begin (prepare-fresh-setup)
                                     (hash-set! h 'version *version*)
                                     (call-with-output-file *config-file* (lambda (p) (write h p)) #:exists 'replace)
                                     h)
                              h))
                        (begin (prepare-fresh-setup)
                               (let ([h (make-hash)])
                                 (hash-set! h 'version *version*)
                                 (call-with-output-file *config-file* (lambda (p) (write h p)) #:exists 'replace)
                                 h))))

(provide/contract [config-item (case-> (symbol? . -> .(or/c any/c #f))
                                       (symbol? any/c . -> . any/c))])
(define config-item
  (case-lambda
    [(sym) (hash-ref *config-hash* sym #f)]
    [(sym val) (hash-set! *config-hash* sym val)
               (call-with-output-file *config-file* (lambda (p) (write *config-hash* p)) #:exists 'replace)
               val]))

