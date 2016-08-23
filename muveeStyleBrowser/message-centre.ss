#lang scheme

(require (only-in scheme/gui queue-callback))

; Representation:
;
; scanners = hash-table[ symbol -> box[ list[ ephemeron[ ref , scanner ] ] ] ]
; scanner = lambda[ msg-as-list -> void ]
; msg-as-list = list[ msg-item ]
; msg-item = any
(define scanners (make-hasheq))

; broadcast = lambda[ msg-id #:rest msg-as-list -> void ]
(provide/contract [broadcast (->* (symbol?) () #:rest any/c void)])
(define (broadcast id . msg)
  (for-each (lambda (s)
              (queue-callback (lambda ()
                                (let ([sv (ephemeron-value s)])
                                  (when sv
                                      (sv msg))))))
            (unbox (hash-ref scanners id (lambda () (box '()))))))

; broadcast-now = same as broadcast, except performs the broadcast
; synchronously, ignoring failures.
(provide/contract [broadcast-now (->* (symbol?) () #:rest any/c void)])
(define (broadcast-now id . msg)
  (for-each (lambda (s)
              (let [(sv (ephemeron-value s))]
                (when sv
                    (with-handlers [(exn:fail? (lambda (e) void))]
                      (sv msg)))))
            (unbox (hash-ref scanners id (lambda () (box '()))))))

(provide receive-for)
(define-syntax receive-for
  (syntax-rules ()
    [(_ ref ((id msg ...) body ...) ...)
     (begin (for-each (lambda (updater-info)
                        (cleanup (first updater-info))
                        (hash-update! scanners
                                      (first updater-info)
                                      (second updater-info)
                                      (lambda () (box '()))))
                      (list (list id (lambda (val)
                                       (set-box! val
                                                 (append (unbox val)
                                                         (list (make-ephemeron ref (lambda (qi)
                                                                                     (match qi
                                                                                       [(list msg ...) body ...]
                                                                                       [_ #f]))))))
                                       val))
                            ...))
            )]))


; A noisy-box broadcasts a message (oldval newval) 
; to all scanners registered under the given id
; whenever its value is changed. oldval and newval 
; are guaranteed to not be equal?. You can change
; the comparator by providing the #:broadcast-unless
; keyword argument, which defaults to equal?.
(provide/contract [noisy-box (->* (symbol? any/c)
                                  (#:broadcast-unless (any/c any/c . -> . boolean?))
                                  (case-> [-> any/c]
                                          [-> any/c any/c]))])
(define (noisy-box id value #:broadcast-unless [comp? equal?])
  (let ([b (box value)])
    (case-lambda
      [() (unbox b)]
      [(newval) (let ([oldval (unbox b)])
                  (unless (comp? oldval newval)
                    (set-box! b newval)
                    (broadcast id oldval newval))
                  newval)])))

; Ditches all lost references. Its essentially an explicit
; garbage collection step for scanners.
(define (cleanup id)
  (let ([v (hash-ref scanners id #f)])
    (when v
      (set-box! v (filter ephemeron-value (unbox v))))))