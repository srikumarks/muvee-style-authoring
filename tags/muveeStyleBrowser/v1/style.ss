#lang scheme/gui

(require net/url
         "webdav.ss"
         "async.ss")

(define (find-muvee-reveal-common-files-folder default-path)
  (let ([result (box default-path)])
    ; Look for the location of MVRT.dll using its CLSID and infer the 
    ; common files folder from its location.
    (if (get-resource "HKEY_LOCAL_MACHINE"
                      "SOFTWARE\\Classes\\CLSID\\{30A8E5D8-A4BD-4038-981E-AD2B7AD781EA}\\InprocServer32\\"
                      result)
        (path-only (unbox result))
        (path->directory-path (string->path (unbox result))))))
  

(define *install-dir* 
  (match (system-type 'os)
    ['windows (find-muvee-reveal-common-files-folder "C:\\Program Files\\Common Files\\muvee Technologies\\071203\\")]
    [_ (string->path "/tmp/installed-styles/")]))

(when (not (directory-exists? *install-dir*))
  (message-box "Error" "Please install muvee Reveal first.\nhttp://www.muvee.com" #f '(ok))
  (exit))
           
(define *warehouse-dir* (let* ([pref (find-system-path 'pref-dir)]
                             [msdir (path->directory-path (build-path pref "muveeStyles"))]
                             [uidir (path->directory-path (build-path msdir "warehouse"))])
                        (make-directory* uidir)
                        uidir))

(define *uninstall-info-file* "uninstall-path.scm")

(provide/contract [my-styles-folder path?])
(define my-styles-folder (path->directory-path (build-path (find-system-path 'pref-dir) "muveeStyles" "collection")))
(make-directory* my-styles-folder)

(define-struct style (id url path icon strings))
(provide/contract [struct style ((id string?) 
                                 (url url?)
                                 (path path?)
                                 (icon (is-a?/c bitmap%))
                                 (strings (and/c hash? immutable?)))])

(provide/contract [style-string (style? symbol? symbol? . -> . string?)])
(define (style-string style key lang)
  (hash-ref (hash-ref (style-strings style) lang) key))

(provide/contract [style-url? ((or/c string? url?) . -> . boolean?)])
(define (style-url? url)
  (if (string? url)
      (style-url? (string->url url))
      (if (string=? (url-scheme url) "file")
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
       (regexp-match #px"^S[[:digit:]]{5}_[[:alnum:]_]+$"
                     (let-values ([(base name must-be-dir?) (split-path path)])
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
        (if (string=? (url-scheme url) "file")
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
      (if (string=? (url-scheme url) "file")
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
      (if (string=? (url-scheme url) "file")
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

(provide/contract [style-warehouse-path (case-> (style? . -> . path?)
                                                (string? string? . -> . path?))])
(define style-warehouse-path
  (case-lambda
    [(s) (style-warehouse-path (url->string (style-url s)) (style-id s))]
    [(url-str id) (path->directory-path (build-path *warehouse-dir* (number->string (equal-hash-code url-str)) id))]))

(define (real-uninstall-path installed-path)
  (let ([uipathfile (build-path installed-path *uninstall-info-file*)])
    (if (file-exists? uipathfile)
        (string->path (call-with-input-file uipathfile read))
        #f)))

(provide/contract [style-installed? (style? . -> . boolean?)])
(define (style-installed? s)
  (and (directory-exists? (style-path s))
       (equal? (real-uninstall-path (style-path s))
               (style-warehouse-path s))))

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
                 [style-prefs-dir (build-path (find-system-path 'pref-dir) "muveeStyles")]
                 [whp (style-warehouse-path url-str style-id-str)])
            
            (make-directory* style-prefs-dir)
            
            (if (directory-exists? whp)
                (path->style url whp)                
                (let ([all-strings (load-string-table-from-file
                                    (webdav-download-file (combine-url/relative url "strings.txt")
                                                          (build-path style-prefs-dir "strings.txt")
                                                          #:use-cache #t))]
                      [icon (load-style-icon (webdav-download-file (combine-url/relative url "icon.png")
                                                                   (build-path style-prefs-dir "icon.png")
                                                                   #:use-cache #t)
                                             64 64)])
                  (make-style style-id-str url style-install-dir icon all-strings)))))))

(define (load-string-table-from-port port)
  (let* ([lines (port->lines port)]
         [parsed (map (lambda (str)
                        (let ([result (regexp-match #px"([[:alnum:]]+)\t([a-zA-Z-]+)\t(.+)" str)])
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

(provide/contract [install-style (style? . -> . any)])
(define (install-style s)
  (with-handlers [(exn:fail? (lambda (e)
                               (display e)
                               (message-box "Error" 
                                            (format "Failed to install style [~a]!" (style-id s))
                                            #f
                                            '(ok caution))
                               #f))]
    (cond
      [(style-installed? s) #t]
      [(directory-exists? (style-warehouse-path s))
       (when (directory-exists? (style-path s))
         (uninstall-unknown-style (style-path s)))
       (rename-file-or-directory (style-warehouse-path s) (style-path s))
       #t]
      [#t (webdav-download-folder (style-url s) (style-warehouse-path s))
          (install-style s)])))

(provide/contract [uninstall-style (style? . -> . any)])
(define (uninstall-style s)
  (if (style-installed? s)
      (begin (rename-file-or-directory (style-path s) (style-warehouse-path s))
             #t)
      #f))

(define (uninstall-unknown-style path-to-installed-style)
  (if (string? path-to-installed-style)
      (uninstall-unknown-style (path->directory-path (string->path path-to-installed-style)))
      (let ([uipathfile (build-path path-to-installed-style *uninstall-info-file*)])
        (if (file-exists? uipathfile)
            (let ([uipath (string->path (call-with-input-file uipathfile read))])
              (rename-file-or-directory path-to-installed-style uipath))
            (begin
              (when (eq? 'yes 
                         (message-box "Warning" 
                                      (format "Delete style directory [~a]?" (path->string path-to-installed-style))
                                      #f
                                      '(yes-no caution)))
                (delete-directory/files path-to-installed-style)))))))
                                 
                                 
(define (dir-modify-seconds dir)
  (if (directory-exists? dir)
      (file-or-directory-modify-seconds dir)
      0))

(provide/contract [update-style (style? . -> . any)])
(define (update-style s)
  (with-handlers [(exn:fail? (lambda (e) (display e) s))]
    (if (not (style-installed? s))
        (let ([whp (style-warehouse-path s)])
          (if (string=? (url-scheme (style-url s)) "file")
              ; then => copy file tree
              (if (> (recursive-path-modify-seconds (url->path (style-url s)))
                     (dir-modify-seconds whp))
                  (begin (when (directory-exists? whp) (delete-directory/files whp))
                         (make-directory* whp)
                         (delete-directory whp)
                         (copy-directory/files (url->path (style-url s)) whp)
                         (call-with-output-file (build-path whp *uninstall-info-file*)
                           (lambda (p) (write (path->string whp) p))
                           #:exists 'replace)
                         (url->style (style-url s)))
                  s)
              ; else => download from webdav
              (if (> (webdav-resource-modify-seconds (style-url s))
                     (dir-modify-seconds whp))
                  (begin (webdav-download-folder (style-url s) whp)
                         (call-with-output-file (build-path whp *uninstall-info-file*)
                           (lambda (p) (write (path->string whp) p))
                           #:exists 'replace)
                         (url->style (style-url s)))
                  s)))
        (begin (uninstall-style s)
               (let ([uds (update-style s)])
                 (install-style uds)
                 uds)))))


(provide/contract [copy-style (style? string? . -> . any)])
(define (copy-style s new-id)
  (if (style-installed? s)
      (dynamic-wind (lambda () (uninstall-style s))
                    (lambda () (copy-style s new-id))
                    (lambda () (install-style s)))
      (let ([dest-path (path->directory-path (build-path my-styles-folder new-id))])
        (update-style s)
        (if (directory-exists? dest-path)
            #f
            (begin (copy-directory/files (style-warehouse-path s) dest-path)
                   (let ([uiinfo (build-path dest-path *uninstall-info-file*)])
                     (when (file-exists? uiinfo)
                       (delete-file uiinfo)))
                   (path->style dest-path))))))
              
              
              
              