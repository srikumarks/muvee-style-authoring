#lang scheme

(require scheme/gui net/url net/sendurl file/zip 
         "config.ss" 
         "style.ss" 
         "async.ss" 
         "webdav.ss"
         "message-centre.ss")

(define (musa ext) (string-append "http://muvee-style-authoring.googlecode.com/" ext))

(define (load-bookmarks)
  (let ([bmfile (build-path *config-dir* "bookmarks.ss")])
    (if (file-exists? bmfile)
        (call-with-input-file bmfile read)
        `(("Examples" . ,(musa "svn/trunk/examples/"))
          ("Tutorial: Basic editing" . ,(musa "svn/trunk/tutorials/BasicEditing/"))
          ("Tutorial: Putting a bounce into Reflections" . ,(musa "svn/trunk/tutorials/ReflectionsWithABounce/"))))))
        
                          
; Load url list for combo box from the net if available.
; Otherwise just construct all the URLs that we know of.
(define *bookmarks* (load-bookmarks))
(define *bookmarks-hash* (make-immutable-hash *bookmarks*))

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
  (hash-ref *bookmarks-hash* str str))

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
               [min-width 480]
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
                  (status "Refreshed [~a]." (style-id new-s))]
                 [('style:copied s new-style)
                  (status "Style [~a] successfully copied to [~a]." (style-id s) (style-id new-style))]
                 [('webdav:begin-download url local-file)
                  (status "Downloading ~a ..." (file-component local-file))]
                 [('webdav:end-download url local-file)
                  (status "Downloading ~a ... done." (file-component local-file))]
                 [('bookmarks:fetched)
                  (status "Bookmarks successfully fetched from muvee-style-authoring.")]
                 [('error:download-folder e url local-dir)
                  (status "Error downloading ~a" (url->string url))]
                 [('error:install-style e s)
                  (status "Error installing style [~a]" (style-id s))]
                 [('error:update-style e s)
                  (status "Error updating style [~a]" (style-id s))]
                 [('error:copy-style e s new-id)
                  (status "Error copying style [~a] to [~a]" (style-id s) new-id)]
                 [('error:synchronize-paths refpath destpath)
                  (status "Error synchronizing [~a] and [~a]." (path->string refpath) (path->string destpath))]
                 [('error:bookmarks-fetch-failed e)
                  (status "Bookmarks not fetched. Network error.")])
    
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
                       (change-style-list (sort result string<? 
                                                #:key (lambda (s)
                                                        (style-string s 'STYLENAME 'en-US))
                                                #:cache-keys? #t)))
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
                  (send this process-url-entry (add-url-choice! (url->string (style-url new-s))))]
                 [('style:deleted s)
                  (send this process-url-entry (first (*choice-history*)))])
    
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
    
    (define url-field (new text-field%
                           [parent navigation-controls]
                           [label "URL:"]
                           [init-value (url-choice "<My styles>")]
                           [callback (lambda (c e)
                                       (when (eq? (send e get-event-type) 'text-field-enter)
                                         (process-url-entry (add-url-choice! (url-choice (send c get-value))))))]
                           [stretchable-width #t]
                           [stretchable-height #f]
                           [horiz-margin 16]))
        
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
    
    (define menu-bar (new menu-bar% [parent this]))
    (define view-menu (new menu%
                           [parent menu-bar]
                           [label "View"]))
    (new menu-item% [parent view-menu]
         [label "Refresh"]
         [callback (lambda (c e)
                     (unless (null? (*choice-history*))
                       (process-url-entry (first (*choice-history*)))))]
         [shortcut 'f5])
    
    
    (define bookmarks-menu (new menu%  
                                [parent menu-bar]
                                [label "Bookmarks"]))
    
    (define (refresh-bookmarks-menu use-internet)
      (let* ([bmfile (build-path *config-dir* "bookmarks.ss")]
             [bms (with-handlers ([exn:fail? (lambda (e)
                                               (broadcast 'error:bookmarks-fetch-failed e)
                                               (load-bookmarks))])
                    (if use-internet
                        ; The internet bookmarks list contains only relative URLs.
                        (begin0 (map (lambda (name-and-url)
                                       (cons (car name-and-url)
                                             (musa (cdr name-and-url))))
                                     (call/input-url (string->url (musa "svn/trunk/muveeStyleBrowser/bookmarks.ss"))
                                                     get-pure-port
                                                     read))
                                (broadcast 'bookmarks:fetched))
                        (error 'no-internet-access)))])
        (call-with-output-file bmfile (lambda (p) (write bms p)) #:exists 'replace)
        (set! *bookmarks* bms)
        (set! *bookmarks-hash* (make-immutable-hash *bookmarks*))
        
        ; Remove all bookmark menu items.
        (for-each (lambda (m)
                    (send m delete))
                  (send bookmarks-menu get-items))
        
        ; Add the refreshed bookmarks.
        (for-each (lambda (name-and-url)
                    (let ([name (car name-and-url)]
                          [url (cdr name-and-url)])
                      (new menu-item% 
                           [parent bookmarks-menu]
                           [label name]
                           [callback (lambda (c e)
                                       (process-url-entry (add-url-choice! url)))])))
                  *bookmarks*)
        
        (add-fetch-bookmarks-command)
        
        bms))

    (define (add-fetch-bookmarks-command)
      ; Add a separator.
      (new separator-menu-item% [parent bookmarks-menu])
      
      (new menu-item%
           [parent bookmarks-menu]
           [label "Fetch bookmarks"]
           [callback (lambda (c e)
                       (refresh-bookmarks-menu #t))]))

    ; Set app icons.
    (let* [(icons-folder (build-path (path-only (find-system-path 'run-file)) "icons"))
           (large (make-object bitmap% (build-path icons-folder "128x128.png") 'png/mask))
           (large-mask (make-object bitmap% (build-path icons-folder "128x128a.xbm") 'xbm))
           (small (make-object bitmap% (build-path icons-folder "16x16.png") 'png/mask))]
      (send this set-icon large large-mask 'large)
      (send this set-icon small (send small get-loaded-mask) 'small))
    
    (refresh-bookmarks-menu #f)
        
    (process-url-entry (add-url-choice! (path->string my-styles-folder)))
    
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
      ; Popup the style menu on left or right click.
      (when (or (send e button-down? 'left) 
                (send e button-down? 'right))
        (send this popup-menu 
              (popup-menu-for-style muvee-style) 
              (max 0 (send e get-x))
              (max 0 (send e get-y))))
      #f)
    
    (super-new [spacing 15]
               [vert-margin 10]
               [horiz-margin 10]
               [stretchable-height #f])
        
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
    
    (init-field the-style)
    
    (define (get-style-url)
      (style-url the-style))
    
    (define (get-style-url-string)
      (url->string (get-style-url)))
    
    (super-new)
    
    (define (edit-file-callback filename)
      (lambda (c e)
        (message-box/custom "Note"
                            (format "Close all editors on \"~a\" before you proceed." filename)
                            "Proceed"
                            #f
                            #f
                            #f
                            '(caution disallow-close default=1))
        (install-style the-style)
        (send-url/file (path->string (build-path (style-path the-style) filename)))))
    
    (if (style-is-local? the-style)
        (begin 
          (unless (style-is-mine? the-style)
            (if (style-installed? the-style)
                (send (new menu-item% [parent this]
                           [label "Style is installed"]
                           [callback (lambda (c e) void)])
                      enable #f)
                (new menu-item% [parent this]
                     [label "Install"]
                     [callback (lambda (c e)
                                 (install-style the-style))])))
                 
          (new menu-item% [parent this]
               [label "Open style folder"]
               [callback (lambda (c e)
                           (send-url (get-style-url-string)))])
          
          (new menu-item% [parent this]
               [label "Edit data.scm"]
               [callback (edit-file-callback "data.scm")])
          
          (new menu-item% [parent this]
               [label "Edit strings.txt"]
               [callback (edit-file-callback "strings.txt")])
          
          (new menu-item% [parent this]
               [label "Derive new style ..."]
               [callback (lambda (c e)
                           (copy-style/gui the-style))])
          
          (new menu-item% [parent this]
               [label "Zip it up ..."]
               [callback (lambda (c e)
                           (when (style-installed? the-style)
                             (update-style the-style))
                           (let* ([s the-style]
                                  [p (url->path (style-url s))])
                             (parameterize ([current-directory (build-path p "..")])
                               (let ([zip-file-path (put-file #f #f #f 
                                                              (string-append (style-id s) ".zip") 
                                                              ".zip" 
                                                              '() 
                                                              '(("Zip files" "*.zip")))])
                                 (when zip-file-path
                                   (when (file-exists? zip-file-path) 
                                     (delete-file zip-file-path))
                                   (status "Creating ~a .." (file-name-from-path zip-file-path))
                                   (dynamic-wind begin-busy-cursor
                                                 (lambda () (zip zip-file-path (style-id s)))
                                                 end-busy-cursor)                   
                                   (send-url/file (path-only zip-file-path))
                                   (status "Created ~a" (path->string (file-name-from-path zip-file-path))))))))])
          
          (new menu-item% [parent this]
               [label "Refresh"]
               [callback (lambda (c e) 
                           (send (send this get-popup-target) 
                                 set-muvee-style (sync-style the-style)))])
          
          (if (style-is-muvee-supplied? the-style)
              (new menu-item% [parent this]
                   [label "Delete ..."]
                   [callback (lambda (c e)
                               (message-box "Note" 
                                            "Cannot delete muvee supplied styles."))])
              (new menu-item% [parent this]
                   [label "Delete ..."]
                   [callback (lambda (c e)
                               (when (= (message-box/custom 
                                         "Warning"
                                         "Your style cannot be recovered if you delete it! "
                                         "Really delete style"
                                         "Cancel"
                                         #f
                                         #f
                                         '(caution default=2))
                                        1)
                                 (let ([path (url->path (style-url the-style))])
                                   (when (directory-exists? path)
                                     (delete-directory/files path)))
                                 (broadcast 'style:deleted the-style)))])))        
          
        (begin 
          (if (style-installed? the-style)
              (send (new menu-item% [parent this]
                         [label "Style is installed"]
                         [callback (lambda (c e) void)])
                    enable #f)
              (new menu-item% [parent this]
                   [label "Download and install"]
                   [callback (lambda (c e)
                               (dynamic-wind begin-busy-cursor
                                             (lambda () (install-style the-style))
                                             end-busy-cursor))]))
          
          (new menu-item% [parent this]
               [label "Derive new style ..."]
               [callback (lambda (c e)
                           (copy-style/gui the-style))])
          
          (new menu-item% [parent this]
               [label "Browse contents"]
               [callback (lambda (c e) (send-url (get-style-url-string)))])
    
          (new menu-item% [parent this]
               [label "View data.scm"]
               [callback (lambda (c e) 
                           (send-url (url->string (combine-url/relative (get-style-url)
                                                                        "data.scm"))))])
          
          (new menu-item% [parent this]
               [label "View strings.txt"]
               [callback (lambda (c e) 
                           (send-url (url->string (combine-url/relative (get-style-url)
                                                                        "strings.txt"))))])))
    
    ))


(define (copy-style/gui s)
  (let ([new-id (get-text-from-user "Style ID (Snnnnn_AlphaNumeric)" 
                                    "Give a new style ID for your copied style."
                                    #f 
                                    (gen-style-id s))])
    (when new-id
      (if (style-id? new-id)
          (begin
            (status "Copying style [~a].." (style-id s))
            (dynamic-wind begin-busy-cursor
                          (lambda () (copy-style s new-id))
                          end-busy-cursor))
          (begin
            (message-box "Error"
                         "Style ids can only have alpha-numeric chars in the name part."
                         #f
                         '(ok caution))
            (copy-style/gui s))))))

(define (sync-style s)
  (status "Synchronizing [~a]..." (style-id s))
  (dynamic-wind begin-busy-cursor
                (lambda () (update-style s))
                end-busy-cursor))

(define main-window (new muvee-styles-frame%))

(define (popup-menu-for-style s)
  (new style-popup-menu%
       [the-style s]))




