#lang scheme/gui

(provide/contract [map/async ((any/c . -> . any/c)
                              (listof any/c)
                              (list? list? . -> . any)
                              (list? . -> . any)
                              (list? . -> . any)
                              . -> . any)])
(define (map/async fun ls progress-proc result-proc error-proc [accumulator '()])
  (if (null? ls)
      (result-proc (reverse accumulator))
      (queue-callback (lambda ()
                        (with-handlers [(exn:fail? (lambda (e) (display e) (error-proc (reverse accumulator))))]
                          (progress-proc accumulator ls)
                          (map/async fun 
                                     (rest ls)
                                     progress-proc
                                     result-proc
                                     error-proc
                                     (cons (fun (first ls)) accumulator)))))))


(provide/contract [for-each/async ((any/c . -> . any)
                                   (listof any/c)
                                   (list? . -> . any)
                                   (exn? . -> . any)
                                   . -> . any)])
(define (for-each/async proc ls progress-proc error-proc)
  (if (null? ls)
      void
      (queue-callback (lambda ()
                        (with-handlers [(exn:fail? (lambda (e) (display e) (error-proc e)))]
                          (progress-proc ls)
                          (proc (first ls))
                          (for-each/async proc (rest ls) progress-proc error-proc))))))
