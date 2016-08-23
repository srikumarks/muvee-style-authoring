#lang scheme

(require scribble/manual scribble/struct scribble/decode scheme/date)
(provide indent current-date site-url code-site-url muveeStyleBrowser New!)

(define-syntax-rule (indent para ...)
  (make-blockquote #f (flow-paragraphs (decode-flow (list para ...)))))
   
;(define (current-date)
;  (date->string (seconds->date (current-seconds))))

(define site-url "http://code.google.com/p/muvee-style-authoring/")
(define code-site-url "http://muvee-style-authoring.googlecode.com/")

(define muveeStyleBrowser (link (string-append site-url "downloads/list") "muveeStyleBrowser"))

(define (New! ver) (margin-note (bold "(New in Reveal " ver "!)")))
