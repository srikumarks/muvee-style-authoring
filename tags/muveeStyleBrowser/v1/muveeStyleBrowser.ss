#lang scheme

(require scheme/gui net/url net/sendurl file/zip "style.ss" "async.ss" "webdav.ss")

(define style-collections
  (list 
   "http://muvee-style-authoring.googlecode.com/svn/trunk/examples/"
   ;   "/Users/kumar/Library/Preferences/muveeStyles/collection/"
   ))

(define *styles-per-page* 8)

(define (status str)
  (send main-window set-status-text str))

(define muvee-styles-frame% 
  (class frame%
    
    (super-new [label "muvee styles"]
               [min-width 320]
               [min-height 20])
    
    (define styles '())
    
    (define (change-style-list new-style-list)
      (if (null? new-style-list)
          (send this set-status-text "No styles available!")
          (begin
            (when list-panel 
              (send this delete-child list-panel) 
              (set! list-panel #f))
            (set! list-panel (new muvee-styles-panel%
                                  [parent this] 
                                  [styles new-style-list]
                                  [page-length *styles-per-page*]))
            (update-page-display)
            (send this refresh))))
    
    (define/public (show-style-collections list-of-collection-urls)
      (send this set-status-text "Scanning for styles...")
      (with-handlers ([exn:fail? (lambda (e) (status "Failed. Maybe network error?"))])
        (let ([urls (apply append (map fetch-style-urls list-of-collection-urls))])
          (map/async url->style 
                     urls
                     (lambda (done todo)
                       (send this set-status-text 
                             (format "Loading...(~a of ~a)" 
                                     (+ 1 (length done))
                                     (+ (length done) (length todo)))))
                     (lambda (result)
                       (send this set-status-text (format "~a styles found" (length result)))
                       (change-style-list result))
                     (lambda (result)
                       (send this set-status-text "Error")
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
    
    (define url-field (new combo-field%
                           [label "URL:"]
                           [parent navigation-controls]
                           [choices (append style-collections (list (path->string my-styles-folder)))]
                           [init-value (first style-collections)]
                           [callback (lambda (c e)
                                       (when (eq? (send e get-event-type) 'text-field-enter)
                                         (process-url-entry (send c get-value))))]
                           [stretchable-width #t]
                           [stretchable-height #f]))
    
    (define my-styles-button
      (new button%
           [label "My styles"]
           [parent navigation-controls]
           [callback (lambda (b e)
                       (let ([path (path->string my-styles-folder)])
                         (send url-field set-value path)
                         (process-url-entry path)))]
           [stretchable-width #f]
           [stretchable-height #f]))
    
    (define prev-button (new button% 
                             [label "<<"]
                             [callback (lambda (b e)
                                         (when list-panel
                                           (send list-panel previous-page)
                                           (update-page-display)))]
                             [parent navigation-controls]
                             [stretchable-width #f]
                             [stretchable-height #f]))
    
    (define page-display (new message% 
                              [label "N/A"]
                              [parent navigation-controls]
                              [auto-resize #t]))
    
    (define next-button (new button%
                             [label ">>"]
                             [callback (lambda (b e)
                                         (when list-panel
                                           (send list-panel next-page)
                                           (update-page-display)))]
                             [parent navigation-controls]
                             [stretchable-width #f]
                             [stretchable-height #f]))
    
    (define (update-page-display)
      (match (send list-panel page-info)
        [(list str left-enable right-enable)
         (send page-display set-label str)
         (send prev-button enable left-enable)
         (send next-button enable right-enable)]))
    
    (define list-panel #f)
    
    (send this create-status-line)
    
    (queue-callback (lambda ()
                      (send this show-style-collections style-collections)
                      (send this show #t)))
    
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
        (end-container-sequence)))
    
    (define/public (previous-page)
      (when (> page 1)
        (select-page (- page 1))))
    
    (define/public (next-page)
      (when (< page (length style-panel-pages))
        (select-page (+ page 1))))
    
    (define/public (page-info)
      (let ([n (length style-panel-pages)])
        (list (format "~a of ~a" page n)
              (and (> n 1) (> page 1))
              (and (> n 1) (< page n)))))
    
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
                                         (dynamic-wind (lambda () (send installed? enable #f))
                                                       (lambda ()
                                                         (if (style-installed? muvee-style)
                                                             ; then => uninstall it
                                                             (uninstall-style muvee-style)
                                                             ; else => install it
                                                             (install-style (refresh-style))))
                                                       (lambda ()
                                                         (send* installed?
                                                           (set-value (style-installed? muvee-style))
                                                           (enable #t)))))))]
           ))
    
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
      (parameterize ([webdav-status status])
        (set! muvee-style (update-style muvee-style))
        (update-ui-fields)
        (status "Ready")
        (send this refresh)
        muvee-style))
    
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
    (super-new)
    
    (new menu-item% [parent this]
         [label "Open style folder"]
         [callback (lambda (c e) (send-url (send this get-style-url-string)))])
    
    (new menu-item% [parent this]
         [label "Edit data.scm"]
         [callback (lambda (c e)
                     (send-url/file (path->string (build-path (url->path (send this get-style-url))
                                                              "data.scm"))))])
    
    (new menu-item% [parent this]
         [label "Edit strings.txt"]
         [callback (lambda (c e)
                     (send-url/file (path->string (build-path (url->path (send this get-style-url))
                                                              "strings.txt"))))])
    
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
                             (status (format "Created ~a" (path->string (file-name-from-path zip-file-path))))
                           )))))])
    
    (new menu-item% [parent this]
         [label "Sync"]
         [callback (lambda (c e) 
                     (send (send this get-popup-target) 
                           set-muvee-style (sync-style (send this get-style))))])
    
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
      (parameterize ([webdav-status status])
        (status (format "Copying style [~a].." (style-id s)))
        (let ([scopy (copy-style s new-id)])
          (if scopy
              (begin
                (status (format "~a copied to ~a." (style-id s) new-id))
                (send main-window process-url-entry (url->string (style-url scopy))))
              (status "Copy failed. Maybe style already exists?")))))))

(define (sync-style s)
  (parameterize ([webdav-status status])
    (status (format "Synchronizing [~a]..." (style-id s)))
    (begin0 (update-style s)
            (status "Sync complete."))))

(define main-window (new muvee-styles-frame%))
(define external-style-popup (new external-style-popup-menu%))
(define my-style-popup (new my-style-popup-menu%))

(define (popup-menu-for-style s)
  (send (if (equal? (url-scheme (style-url s)) "file")
            my-style-popup
            external-style-popup)
        set-style s))




