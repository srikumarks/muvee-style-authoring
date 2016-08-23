#lang scheme

(require scheme/gui net/url net/sendurl file/zip "config.ss" "style.ss" "async.ss" "webdav.ss" "message-centre.ss")

(define (musa ext) (string-append "http://muvee-style-authoring.googlecode.com/" ext))

; Load url list for combo box from the net if available.
; Otherwise just construct all the URLs that we know of.
(define *special-urls*
  (hash-set 
   (with-handlers ([exn:fail? (lambda (e)
                                (make-immutable-hash
                                 `(("<Examples>" . ,(musa "svn/trunk/examples/"))
                                   ("<Tutorial:BasicEditing>" . ,(musa "svn/trunk/tutorials/BasicEditing/")))))])
     (make-immutable-hash
      (hash-map (call/input-url (musa "svn/trunk/muveeStyleBrowser/std-urls.ss")
                                get-pure-port
                                read)
                (lambda (k v)
                  (cons k (musa v))))))
   "<My styles>"
   (path->string my-styles-folder)))

; Pass on the sorted URL key list to the choice box.
(define *choices* (sort (hash-map *special-urls* (lambda (k v) k)) string<?))

; A simple mechanism to track URL change history.
(define *choice-history* (make-parameter '()))
(define (add-url-choice! ch)
  (if (null? (*choice-history*))
      (begin (*choice-history* (cons ch (*choice-history*)))
             (broadcast 'empty-url-history))
      (unless (equal? (first (*choice-history*)) ch)
        (*choice-history* (cons ch (*choice-history*)))
        (broadcast 'new-url-history ch)))
  ch)
(define (back-url-choice?) (and (not (null? (*choice-history*)))
                                (not (null? (rest (*choice-history*))))))
(define (back-url-choice!)
  (if (back-url-choice?)
      (begin0 (second (*choice-history*))
              (*choice-history* (rest (*choice-history*)))
              (unless (back-url-choice?)
                (broadcast 'empty-url-history)))
      (begin0 #f
              (broadcast 'empty-url-history))))

; Either treats str as a special keyed url reference
; or simply returns str.
(define (url-choice str)
  (hash-ref *special-urls* str str))

(define *styles-per-page* 8)

; major-status will mask all subsequent
; status calls until normal-status is called.
(define *major-status* #f)
(define (raw-status . str)
  (send main-window set-status-text (apply format str)))  
(define (major-status . str)
  (set! *major-status* #t)
  (apply raw-status str))
(define (normal-status . str)
  (set! *major-status* #f)
  (apply raw-status str))
(define (status . str)
  (unless *major-status*
    (apply raw-status str)))

; Returns the file.ext part of the path.
(define (file-component path)
  (let-values ([(base name must-be-dir?) (split-path path)])
    (path->string name)))

(define muvee-styles-frame% 
  (class frame%
    
    (super-new [label "muvee styles"]
               [min-width 320]
               [min-height 20])
    
    (define styles '())
    
    ; Status display.
    (receive-for this
                 [('status text) (status text)]
                 [('style:installed s) 
                  (status "Style [~a] successfully installed." (style-id s))]
                 [('style:uninstalled s)
                  (status "Style [~a] successfully uninstalled." (style-id s))]
                 [('style:updated s new-s)
                  (status "Synchronized [~a]." (style-id new-s))]
                 [('style:copied s new-style)
                  (status "Style [~a] successfully copied to [~a]." (style-id s) (style-id new-style))]
                 [('webdav:begin-download url local-file)
                  (status "Downloading ~a ..." (file-component local-file))]
                 [('webdav:end-download url local-file)
                  (status "Downloading ~a ... done." (file-component local-file))]
                 [('error:download-folder e url local-dir)
                  (status "Error downloading ~a" (url->string url))]
                 [('error:install-style e s)
                  (status "Error installing style [~a]" (style-id s))]
                 [('error:update-style e s)
                  (status "Error updating style [~a]" (style-id s))]
                 [('error:copy-style e s new-id)
                  (status "Error copying style [~a] to [~a]" (style-id s) new-id)]
                 [('error:synchronize-paths refpath destpath)
                  (status "Error synchronizing [~a] and [~a]." (path->string refpath) (path->string destpath))])
    
    (define (change-style-list new-style-list)
      (if (null? new-style-list)
          (status "No styles available!")
          (begin
            (when list-panel 
              (send this delete-child list-panel) 
              (set! list-panel #f))
            (set! list-panel (new muvee-styles-panel%
                                  [parent this] 
                                  [styles new-style-list]
                                  [page-length *styles-per-page*])))))
    
    (define/public (show-style-collections list-of-collection-urls)
      (status "Scanning for styles...")
      (with-handlers ([exn:fail? (lambda (e) (status "Failed. Maybe network error?"))])
        (let ([urls (apply append (map fetch-style-urls list-of-collection-urls))])
          (map/async url->style 
                     urls
                     (lambda (done todo)
                       (major-status "Loading...(~a of ~a)" 
                                     (+ 1 (length done))
                                     (+ (length done) (length todo))))
                     (lambda (result)
                       (normal-status "~a styles found" (length result))
                       (change-style-list result))
                     (lambda (result)
                       (normal-status "Error")
                       (message-box "Error"
                                    "Error occurred when scanning URL for styles!"
                                    #f
                                    '(ok caution))
                       (when (not (null? result))
                         (change-style-list result)))))))
    
    
    (define navigation-controls (new horizontal-panel%
                                     [parent this]
                                     [stretchable-width #t]
                                     [stretchable-height #f]
                                     [vert-margin 10]
                                     [horiz-margin 10]))
    
    
    (define/public (process-url-entry entry)
      (send url-field set-value entry)
      (let ([entry->path-url (lambda ()
                               (path->url (path->directory-path
                                           (string->path entry))))])
        (queue-callback
         (cond
           [(and (directory-exists? entry)
                 (style-url? (entry->path-url)))
            (lambda ()
              (change-style-list (list (url->style (entry->path-url)))))]
           [(directory-exists? entry)
            (lambda ()
              (show-style-collections (list (entry->path-url))))]
           [else (if (style-url? entry)
                     (lambda ()
                       (change-style-list (list (url->style entry))))
                     (lambda ()
                       (send this show-style-collections (list entry))))]))))
    
    (receive-for this 
                 [('style:copied s new-s)
                  (send this process-url-entry (add-url-choice! (url->string (style-url new-s))))])
    
    (define back-button (new button%
                             [label "Back"]
                             [parent navigation-controls]
                             [callback (lambda (c e)
                                         (let ([ch (back-url-choice!)])
                                           (when ch
                                             (process-url-entry ch))))]
                             [enabled #f]))
    
    (receive-for back-button 
                 [('empty-url-history) (send back-button enable #f)]
                 [('new-url-history ch) (send back-button enable #t)])
    
    (define url-field (new combo-field%
                           [label "URL:"]
                           [parent navigation-controls]
                           [choices *choices*]
                           [init-value (url-choice "<Examples>")]
                           [callback (lambda (c e)
                                       (when (eq? (send e get-event-type) 'text-field-enter)
                                         (process-url-entry (add-url-choice! (url-choice (send c get-value))))))]
                           [stretchable-width #t]
                           [stretchable-height #f]))
    
    (define my-styles-button
      (new button%
           [label "My styles"]
           [parent navigation-controls]
           [callback (lambda (b e)
                       (let ([path (path->string my-styles-folder)])
                         (send url-field set-value path)
                         (process-url-entry (add-url-choice! path))))]
           [stretchable-width #f]
           [stretchable-height #f]))
    
    (define prev-button (new button% 
                             [label "<<"]
                             [callback (lambda (b e)
                                         (when list-panel
                                           (send list-panel previous-page)))]
                             [parent navigation-controls]
                             [stretchable-width #f]
                             [stretchable-height #f]))
    
    (receive-for prev-button
                 [('page-changed p n) 
                  (send prev-button enable (and (> n 1) (> p 1)))])
    
    (define page-display (new message% 
                              [label "N/A"]
                              [parent navigation-controls]
                              [auto-resize #t]))
    
    (receive-for page-display
                 [('page-changed p n) 
                  (send page-display set-label (format "~a of ~a" p n))])
    
    (define next-button (new button%
                             [label ">>"]
                             [callback (lambda (b e)
                                         (when list-panel
                                           (send list-panel next-page)))]
                             [parent navigation-controls]
                             [stretchable-width #f]
                             [stretchable-height #f]))
    
    (receive-for next-button
                 [('page-changed p n) 
                  (send next-button enable (and (> n 1) (< p n)))])
    
    (define list-panel #f)
    
    (send this create-status-line)
    
    (process-url-entry (add-url-choice! (url-choice "<Examples>")))
    
    (send this show #t)
    ))

(define muvee-styles-panel%
  (class vertical-panel%
    (init-field styles)
    (init-field page-length)
    (super-new)
    
    (define page 1)
    
    (define style-panels (map (lambda (x) 
                                (new muvee-style-panel% 
                                     [parent this] 
                                     [muvee-style x]
                                     [style '(deleted)]))
                              styles))
    
    (define style-panel-pages (page-split style-panels page-length '()))
    
    (define/public (get-page) page)
    
    (define/public (select-page p)
      (set! page p)
      (send* this 
        (begin-container-sequence)
        (change-children (lambda (prev-children) (list-ref style-panel-pages (- page 1))))
        (end-container-sequence))
      (broadcast 'page-changed p (length style-panel-pages)))
    
    (define/public (previous-page)
      (when (> page 1)
        (select-page (- page 1))))
    
    (define/public (next-page)
      (when (< page (length style-panel-pages))
        (select-page (+ page 1))))
    
    (select-page 1)
    
    ))

(define (page-split items page-size acc)
  (if (null? items)
      (reverse acc)
      (if (< (length items) page-size)
          (page-split '() page-size (cons (apply list items) acc))
          (let-values ([(prefix suffix) (split-at items page-size)])
            (page-split suffix page-size (cons prefix acc))))))

(define muvee-style-panel%
  (class horizontal-panel%
    (init-field muvee-style)
    
    (define/public (set-muvee-style s)
      (set! muvee-style s)
      (update-ui-fields))
    
    (define/override (on-subwindow-event r e)
      (when (send e button-down? 'right)
        (send this popup-menu 
              (popup-menu-for-style muvee-style) 
              (max 0 (send e get-x))
              (max 0 (send e get-y))))
      #f)
    
    (super-new [spacing 15]
               [vert-margin 10]
               [horiz-margin 10]
               [stretchable-height #f])
    
    (define installed?  
      (new check-box% 
           [parent this]
           [label ""]
           [value (style-installed? muvee-style)]
           [callback (lambda (chk ev)
                       (queue-callback (lambda ()
                                         (dynamic-wind
                                          (lambda () 
                                            (send installed? enable #f))
                                          (lambda ()
                                            (if (style-installed? muvee-style)
                                                ; then => uninstall it
                                                (uninstall-style muvee-style)
                                                (install-style (refresh-style))))
                                          (lambda ()
                                            (send installed? enable #t))))))]))
    
    ; Check box update.
    (receive-for installed?
                 [('style:installed s) (when (eq? s muvee-style)
                                         (send* installed? (set-value #t) (enable #t)))]
                 [('style:uninstalled s) (when (eq? s muvee-style)
                                           (send* installed? (set-value #f) (enable #t)))]
                 [('style:updated s new-s) (when (eq? new-s muvee-style)
                                             (update-ui-fields)
                                             (send installed? enable #t))]
                 [('error:install-style e s) (when (eq? s muvee-style)
                                               (send installed? enable #f))]
                 [('error:uninstall-style e s) (when (eq? s muvee-style)
                                                 (send installed? enable #f))]
                 [('error:update-style e s) (when (eq? s muvee-style)
                                              (send installed? enable #f))]
                 )
    
    (define icon (new message% 
                      [parent this] 
                      [label (style-icon muvee-style)]
                      [auto-resize #t]))
    
    (define name-and-description (new vertical-panel%
                                      [parent this]
                                      [alignment '(left top)]))
    
    (define name (new message% 
                      [parent name-and-description] 
                      [label (style-string muvee-style 'STYLENAME 'en-US)]
                      [auto-resize #t]))
    
    (define description (new message% 
                             [parent name-and-description] 
                             [label (style-string muvee-style 'STYLEDESC 'en-US)]
                             [auto-resize #t]))
    
    (define/public (refresh-style)
      (set! muvee-style (update-style muvee-style))
      muvee-style)
    
    (define (update-ui-fields)
      (send icon set-label (style-icon muvee-style))
      (send name set-label (style-string muvee-style 'STYLENAME 'en-US))
      (send description set-label (style-string muvee-style 'STYLEDESC 'en-US)))
    
    ))

(define style-popup-menu%
  (class popup-menu%
    
    (define the-style #f)
    
    (define/public (set-style s)
      (set! the-style s)
      this)
    
    (define/public (get-style) the-style)
    
    (define/public (get-style-url)
      (style-url (send this get-style)))
    
    (define/public (get-style-url-string)
      (url->string (get-style-url)))
    
    (super-new)
    ))

(define my-style-popup-menu%
  (class style-popup-menu%
    
    (define/override (get-style) (let ([s (sync-style (super get-style))])
                                   (send this set-style s)
                                   s))
    
    (super-new)
    
    (new menu-item% [parent this]
         [label "Open style folder"]
         [callback (lambda (c e) (send-url (send this get-style-url-string)))])
    
    (define (edit-file-callback filename)
      (lambda (c e)
        (message-box/custom "Note"
                            (format "Close all editors on \"~a\" before you proceed." filename)
                            "Proceed"
                            #f
                            #f
                            #f
                            '(caution disallow-close default=1))
        (let ([s (send this get-style)])
          (send-url/file (path->string (build-path (deployed-style-path s) filename))))))
    
    (new menu-item% [parent this]
         [label "Edit data.scm"]
         [callback (edit-file-callback "data.scm")])
    
    (new menu-item% [parent this]
         [label "Edit strings.txt"]
         [callback (edit-file-callback "strings.txt")])
    
    (new menu-item% [parent this]
         [label "Copy style (create variant) ..."]
         [callback (lambda (c e)
                     (copy-style/gui (send this get-style)))])
    
    (new menu-item% [parent this]
         [label "Zip it up ..."]
         [callback (lambda (c e)
                     (let* ([s (send this get-style)]
                            [p (url->path (style-url s))])
                       (parameterize ([current-directory (build-path p "..")])
                         (let ([zip-file-path (put-file #f #f #f 
                                                        (string-append (style-id s) ".zip") 
                                                        ".zip" 
                                                        '() 
                                                        '(("Zip files" "*.zip")))])
                           (when zip-file-path
                             (zip zip-file-path (style-id s))
                             (send-url/file (path-only zip-file-path))
                             (status "Created ~a" (path->string (file-name-from-path zip-file-path))))))))])
    
    (new menu-item% [parent this]
         [label "Sync"]
         [callback (lambda (c e) 
                     (send (send this get-popup-target) 
                           set-muvee-style (send this get-style)))])
    
    ))

(define external-style-popup-menu%
  (class style-popup-menu%
    (super-new)
    
    (new menu-item% [parent this]
         [label "Browse style contents"]
         [callback (lambda (c e) (send-url (send this get-style-url-string)))])
    
    (new menu-item% [parent this]
         [label "View data.scm"]
         [callback (lambda (c e) 
                     (send-url (url->string (combine-url/relative (send this get-style-url)
                                                                  "data.scm"))))])
    
    (new menu-item% [parent this]
         [label "Copy style (make editable) ..."]
         [callback (lambda (c e)
                     (copy-style/gui (send this get-style)))])
    
    (new menu-item% [parent this]
         [label "Sync"]
         [callback (lambda (c e) 
                     (send (send this get-popup-target) 
                           set-muvee-style (sync-style (send this get-style))))])
    
    ))

(define (copy-style/gui s)
  (let ([new-id (get-text-from-user "Style ID" 
                                    "Give a new style ID for your copied style" 
                                    #f 
                                    (string-append (style-id s) "_copy"))])
    (when new-id
      (status "Copying style [~a].." (style-id s))
      (copy-style s new-id))))

(define (sync-style s)
  (status "Synchronizing [~a]..." (style-id s))
  (update-style s))

(define main-window (new muvee-styles-frame%))
(define external-style-popup (new external-style-popup-menu%))
(define my-style-popup (new my-style-popup-menu%))

(define (popup-menu-for-style s)
  (send (if (equal? (url-scheme (style-url s)) "file")
            my-style-popup
            external-style-popup)
        set-style s))




