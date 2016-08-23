#lang scheme

(require scribble/manual scribble/struct scribble/decode)
(provide effect-parameter-table input-and-imageop)

(define spacer (hspace 1))
(define (->flow e) 
  (cond
    ((flow? e) e)
    ((list? e) (decode-flow e))
    ((paragraph? e) (make-flow (list e)))
    (#t (make-flow (list (make-paragraph (list e)))))))

(define (** f) (lambda (x) (map f x)))

(define-syntax-rule 
  (effect-parameter-table [property default range description] ...)
   (*generate-table (list (list spacer 
                              (scheme property) 
                              spacer 
                              (scheme default) 
                              spacer 
                              range 
                              spacer 
                              description)
                        ...)))

(define (add-line-separator rows)
  (let ((separator (list spacer "" spacer "" spacer "" spacer "")))
    (define (sep rows acc)
      (if (eq? rows '())
          (reverse acc)
          (if (eq? (rest rows) '())
              (sep (rest rows) (cons (first rows) acc))
              (sep (rest rows) (cons separator (cons (first rows) acc))))))
    (sep rows '())))

(define (*generate-table rows)
   (make-table 'boxed
               (cons (map ->flow (list spacer 
                                    (bold "Parameters")
                                    spacer 
                                    (bold "Default") 
                                    spacer 
                                    (t (bold "Range") (hspace 4))
                                    spacer 
                                    (bold "Description")))
                     (if (eq? rows '())
                         (list (map ->flow (list spacer (emph "None") spacer "" spacer "" spacer "")))
                         (map (** ->flow) (add-line-separator rows))))))

(define-syntax-rule 
  (input-and-imageop input-pattern image-op)
  (make-splice (list (make-paragraph
                      (list (bold "Input pattern") ": " (scheme input-pattern)))
                     (make-paragraph
                      (cond 
                        ((equal? image-op #t) (list (bold (tech "Image-Op")) ": Yes"))
                        ((equal? image-op #f) (list (bold (tech "Image-Op")) ": No"))
                        ((string? image-op) (list (bold (tech "Image-Op")) ": " image-op))
                        (#t (append (list (bold (tech "Image-Op")) ": ")
                                    image-op)))))))