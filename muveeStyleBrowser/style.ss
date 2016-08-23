#lang scheme/gui

(require net/url
         (only-in mzlib/pregexp
                  pregexp-match
                  pregexp-replace)
         "message-centre.ss"
         "config.ss"
         "webdav.ss"
         "async.ss")

(define-struct style (id url path icon strings))
(provide/contract [struct style ((id string?) 
                                 (url url?)
                                 (path path?)
                                 (icon (is-a?/c bitmap%))
                                 (strings (and/c hash? immutable?)))])

(provide/contract [style-string (style? symbol? symbol? . -> . string?)])
(define (style-string style key lang)
  (hash-ref (hash-ref (style-strings style) lang) key))

(define (change-string! table lang id proc)
  (hash-update! table
                lang
                (lambda (langtable)
                  (hash-update! langtable
                                id
                                proc
                                #f)
                  langtable)
                make-hasheq))

(provide/contract [style-id? (string? . -> . boolean?)])
(define (style-id? str)
  (and (regexp-match #px"^S[[:digit:]]{5}_[[:alnum:]_]+$" str)
       #t))

(provide/contract [style-url? ((or/c string? url?) . -> . boolean?)])
(define (style-url? url)
  (if (string? url)
      (style-url? (string->url url))
      (if (url-scheme-is-file? url)
          (style-path? (url->path url))
          (and (webdav-directory-exists? url)
               (regexp-match #px"/(S[[:digit:]]{5}_[[:alnum:]_]+)/$" (url->string url))
               (let ([contents (webdav-directory-list url)])
                 (and (memf (lambda (s) (string=? s "data.scm")) contents)
                      (memf (lambda (s) (string=? s "strings.txt")) contents)
                      (memf (lambda (s) (string=? s "icon.png")) contents)
                      #t))))))

(define (style-path? path)
  (and (directory-exists? path)
       (style-id? (let-values ([(base name must-be-dir?) (split-path path)])
                    (path->string name)))
       (let ((contents (map path->string (directory-list path))))
         (and (memf (lambda (s) (string-ci=? s "data.scm")) contents)
              (memf (lambda (s) (string-ci=? s "strings.txt")) contents)
              (memf (lambda (s) (string-ci=? s "icon.png")) contents)
              #t))))


(provide/contract [fetch-styles ((or/c string? url?) . -> . (listof style?))])
(define (fetch-styles url)
  (with-handlers [(exn:fail? (lambda (e) '()))]
    (if (string? url)
        (fetch-styles (string->url url))
        (if (url-scheme-is-file? url)
            ; then -> scan the given directory for style folders.
            (fetch-style-list-from-folder (url->path url))
            ; else -> read the url as a webdav directory and get style folders.
            (fetch-style-list-from-webdav-folder url)))))

(provide/contract [fetch-styles/async ((or/c string? url?) 
                                       (list? list? . -> . any)
                                       (list? . -> . any)
                                       (list? . -> . any)
                                       . -> . any)])
(define (fetch-styles/async url progress-proc result-proc error-proc)
  (if (string? url)
      (fetch-styles/async (string->url url) progress-proc result-proc error-proc)
      (if (url-scheme-is-file? url)
          ; then -> scan the given directory for style folders.
          (fetch-style-list-from-folder/async (url->path url) progress-proc result-proc error-proc)
          ; else -> read the url as a webdav directory and get style folders.
          (fetch-style-list-from-webdav-folder/async url progress-proc result-proc error-proc))))

(define (fetch-style-list-from-folder path)
  (if (directory-exists? path)
      ; then -> Scan the directory
      (let* ([files-and-dirs (directory-list path)]
             [full-paths (map (lambda (f) (path->complete-path f path))
                              files-and-dirs)]
             [only-styles (filter style-path? full-paths)])
        (map path->style only-styles))
      
      ; else -> raise exception
      (raise 'exn:path-not-a-valid-directory)
      ))

(define (fetch-style-list-from-folder/async path progress-proc result-proc error-proc)
  (if (directory-exists? path)
      ; then -> Scan the directory
      (let* ([files-and-dirs (directory-list path)]
             [full-paths (map (lambda (f) (path->complete-path f path))
                              files-and-dirs)]
             [only-styles (filter style-path? full-paths)])
        (map/async path->style only-styles progress-proc result-proc error-proc))
      
      ; else -> raise exception
      (raise 'exn:path-not-a-valid-directory)
      ))


(define (fetch-style-list-from-webdav-folder url) 
  (map url->style (fetch-style-urls url)))

(define (fetch-style-list-from-webdav-folder/async url progress-proc result-proc error-proc) 
  (map/async url->style (fetch-style-urls url) progress-proc result-proc error-proc))

(provide/contract [fetch-style-urls ((or/c string? url?) . -> . (listof url?))])
(define (fetch-style-urls url)
  (if (string? url)
      (fetch-style-urls (if (directory-exists? (string->path url))
                            (path->url (string->path url))
                            (string->url url)))
      (if (url-scheme-is-file? url)
          (let* ([path (url->path url)]
                 [files-and-dirs (directory-list path)]
                 [full-paths (map (lambda (f) (path->complete-path f path))
                                  files-and-dirs)]
                 [only-styles (filter style-path? full-paths)])
            (map path->url only-styles))
          (let* ([files-and-dirs (webdav-directory-list url)]
                 [full-urls (map (lambda (u) (combine-url/relative url u)) files-and-dirs)]
                 [only-styles (filter style-url? full-urls)])
            only-styles))))

(provide/contract [style-installed? (style? . -> . boolean?)])
(define (style-installed? s)
  (directory-exists? (style-path s)))

(provide/contract [style-is-mine? (style? . -> . boolean?)])
(define (style-is-mine? s)
  (and (style-installed? s)
       (url-scheme-is-file? (style-url s))
       (string-ci=? (path->string (url->path (style-url s)))
                    (path->string (style-path s)))))

(provide/contract [style-id-number (style? . -> . exact-integer?)])
(define (style-id-number s)
  (string->number (second (regexp-match #px"^S([[:digit:]]{5})_[[:alnum:]_]+$" (style-id s)))))

(provide/contract [style-is-muvee-supplied? (style? . -> . boolean?)])
(define (style-is-muvee-supplied? s)
  (and (style-is-mine? s)
       (not (= (style-id-number s) 10000))))

(provide/contract [style-is-local? (style? . -> . boolean?)])
(define (style-is-local? s)
  (url-scheme-is-file? (style-url s)))

(define (load-style-icon path max-width max-height)
  (let* ([bmp (make-object bitmap% path)]
         [w (send bmp get-width)]
         [h (send bmp get-height)]
         [wf (if (> w max-width) (/ max-width w) 1)]
         [hf (if (> h max-height) (/ max-height h) 1)]
         [f (if (> wf hf) hf wf)]
         [wfinal (round (* w f))]
         [hfinal (round (* h f))]
         [destbmp (make-object bitmap% wfinal hfinal)]
         [destbmpdc (new bitmap-dc% [bitmap destbmp])])
    (send destbmpdc draw-bitmap-section-smooth bmp 0 0 wfinal hfinal 0 0 w h #f)
    (send destbmpdc set-bitmap #f)
    destbmp))

(define path->style
  (case-lambda
    [(path) (path->style (path->url path) path)]
    [(url path) (let*-values ([(base style-id must-be-dir?) (split-path path)]
                              [(style-id-str) (path->string style-id)]
                              [(style-install-dir) (build-path *install-dir* style-id-str)]
                              [(all-strings) (load-string-table-from-file (build-path path "strings.txt"))])
                  
                  (make-style style-id-str 
                              url
                              style-install-dir
                              (load-style-icon (build-path path "icon.png") 64 64)
                              all-strings))]))

(provide/contract [url->style ((or/c string? url?) . -> . style?)])
(define (url->style url)
  (if (string? url)
      (url->style (if (directory-exists? (string->path url))
                      (path->url (string->path url))
                      (string->url url)))
      (if (string=? (url-scheme url) "file")
          ; then => Given style folder on local machine
          (path->style (url->path url))
          
          ; else => given webdav URL
          (let* ([url-str (url->string url)]
                 [style-id-str (second (regexp-match #px"/(S[[:digit:]]{5}_[[:alnum:]_]+)/?$" url-str))]
                 [style-install-dir (build-path *install-dir* style-id-str)]
                 [style-prefs-dir (build-path (find-system-path 'pref-dir) "muveeStyles")])
            
            (make-directory* style-prefs-dir)
            
            (let ([all-strings (load-string-table-from-file
                                (webdav-download-file (combine-url/relative url "strings.txt")
                                                      (build-path style-prefs-dir "strings.txt")
                                                      #:use-cache #t))]
                  [icon (load-style-icon (webdav-download-file (combine-url/relative url "icon.png")
                                                               (build-path style-prefs-dir "icon.png")
                                                               #:use-cache #t)
                                         64 64)])
              (make-style style-id-str url style-install-dir icon all-strings))))))

(define (load-string-table-from-port port)
  (let* ([lines (port->lines port)]
         [parsed (map (lambda (str)
                        (let ([result (regexp-match #px"[[:space:]]*([[:alnum:]]+)\t([a-zA-Z-]+)\t(.+)" str)])
                          (if result (rest result) #f)))
                      lines)]
         [only-useful-lines (filter (lambda (x) x) parsed)]
         [langcodes (make-hasheq)])
    (for-each (lambda (entry)
                (let* ([langcode (string->symbol (second entry))]
                       [langstrs (hash-ref langcodes langcode (make-hasheq))])
                  
                  (hash-set! langstrs (string->symbol (first entry)) (third entry))
                  (hash-set! langcodes langcode langstrs)))
              only-useful-lines)
    
    langcodes))

(define (load-string-table-from-file path)
  (if path
      (call-with-input-file path load-string-table-from-port)
      (make-hasheq)))

(define (write-string-table-to-file table path)
  (call-with-output-file path
    (lambda (p)
      (hash-for-each table 
                     (lambda (langcode langtable)
                       (hash-for-each langtable 
                                      (lambda (id text)
                                        (display (format "~a\t~a\t~a\n" id langcode text) p)))
                       (display "\n\n" p))))))

(provide/contract [install-style (style? . -> . any)])
(define (install-style s)
  (with-handlers [(exn:fail? (lambda (e)
                               (broadcast 'error:install-style e s)
                               #f))]
    (cond
      [(style-is-local? s)
       (synchronize-paths (url->path (style-url s)) (style-path s))
       (broadcast 'style:installed s)
       #t]
      [#t (webdav-download-folder (style-url s) (style-path s))
          (broadcast 'style:installed s)
          #t])))

(define (ensure-parent-path-exists p)
  (let ([p-parent (simplify-path (build-path p 'up) #f)])
    (when (not (directory-exists? p-parent))
      (make-directory* p-parent)))
  p)

(define (dir-modify-seconds dir)
  (if (directory-exists? dir)
      (file-or-directory-modify-seconds dir)
      0))

(provide/contract [update-style (style? . -> . any)])
(define (update-style s)
  (with-handlers [(exn:fail? (lambda (e) 
                               (broadcast 'error:update-style e s)
                               s))]
    (let* ([dep (style-path s)])
      (if (url-scheme-is-file? (style-url s))
          ; then => copy file tree.
          (if (directory-exists? dep)
              (synchronize-paths (url->path (style-url s)) dep)
              (begin (make-directory* (simplify-path (build-path dep 'up) #f))
                     (copy-directory/files (url->path (style-url s)) dep)))
          ; else => download from webdav.
          (if (> (webdav-style-modify-seconds s)
                 (dir-modify-seconds dep))
              (webdav-download-folder (style-url s) dep)
              s)))
    (let ([new-s (url->style (style-url s))])
      (broadcast 'style:updated s new-s)
      new-s)))

(define (webdav-style-modify-seconds s)
  (let* ([u (style-url s)]
         [ud (combine-url/relative u "data.scm")]
         [us (combine-url/relative u "strings.txt")])
    (max (webdav-resource-modify-seconds u)
         (webdav-resource-modify-seconds ud)
         (webdav-resource-modify-seconds us))))
    
; Generate a locally unique style id for a copy of the given style.
(provide/contract [gen-style-id (style? . -> . string?)])
(define (gen-style-id s)
  ; 1. Discard any deployment number that the style has and use 10000 for the copy.
  ; 2. Append copyN, trying successive N until one style with that name doesn't exist.
  (let* [(idcopy (string-append (pregexp-replace #px"^S[0-9]{5}_" (style-id s) "S10000_") "_copy"))
         (expected-path (build-path my-styles-folder idcopy))]
    (if (directory-exists? expected-path)
        (let loop ([i 2] [base (path->string expected-path)])
          (if (directory-exists? (string-append base (number->string i)))
              (loop (+ i 1) base) ; Try the next number.
              (string-append idcopy (number->string i))))
        idcopy)))
  
(provide/contract [copy-style (style? string? . -> . any)])
(define (copy-style s new-id)
  (with-handlers ([exn:fail? (lambda (e)
                               (display e)
                               (broadcast 'error:copy-style e s new-id)
                               #f)])
    (let* ([dest-path (path->directory-path (build-path my-styles-folder new-id))]
           [on-copy (lambda ()
                      (let ([new-style (path->style dest-path)])
                        (broadcast 'style:copied s new-style)
                        new-style))])
      (if (style-is-local? s)
          (begin 
            (update-style s)
            (if (directory-exists? dest-path)
                #f
                (begin (copy-directory/files (style-path s) dest-path)
                       (on-copy))))
          (begin
            (webdav-download-folder (style-url s) dest-path)
            (on-copy))))))
              

(provide/contract [synchronize-paths (path? path? . -> . void)])
(define (synchronize-paths refpath destpath)
  (cond
    [(directory-exists? refpath) (if (directory-exists? destpath)
                                     (let* ([dirlist (directory-list refpath)]
                                            [contents (map (lambda (p) (build-path refpath p)) dirlist)]
                                            [targets (map (lambda (p) (build-path destpath p)) dirlist)])
                                       (for-each (lambda (c t)
                                                   (synchronize-paths c t))
                                                 contents
                                                 targets))
                                     (copy-directory/files refpath destpath))]
    [(file-exists? refpath) (if (file-exists? destpath)
                                (let ([reftime (file-or-directory-modify-seconds refpath)]
                                      [desttime (file-or-directory-modify-seconds destpath)])
                                  (cond ; Update the older file to the newer version.
                                    [(> reftime desttime) (copy-file/replace refpath destpath)]
                                    [(> desttime reftime) (copy-file/replace destpath refpath)]
                                    [#t void]))
                                (copy-file refpath destpath))]
    [#t (broadcast 'error:synchronize-paths refpath destpath)]))

(define (copy-file/replace src dest)
  (call-with-input-file src 
    (lambda (in)
      (call-with-output-file dest
        (lambda (out)
          (copy-port in out))
        #:exists 'replace))))
          
(define (url-scheme-is-file? url)
  (string=? (url-scheme url) "file"))
