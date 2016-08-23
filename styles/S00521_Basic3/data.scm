;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00521_Basic3
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (discrete-slider	SQUARE_SIZE	3	1    5))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed
;   - transfer curves subdomain mapping

(let ((tc-mid (+ (* AVERAGE_SPEED 0.5) 0.25))
      (tc-dev (* MUSIC_RESPONSE 0.25)))
  (map-tc-subdomain (- tc-mid tc-dev) (+ tc-mid tc-dev)))

(segment-durations 4.0)

(segment-duration-tc 0.00  8.00
                     0.25  4.00
                     0.50  1.00
                     0.75  0.25
                     1.00  0.125)

(time-warp-tc 0.00  0.125
              0.25  0.25
              0.375 0.50
              0.50  1.00
              1.00  1.00)

(preferred-transition-duration 1.5)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00  8.00
                        0.25  4.00
                        0.50  1.00
                        0.75  0.25
                        1.00  0.125)


;-----------------------------------------------------------
;   Helper functions

;;; grid transformations ;;;

(define transpose-xy
  (fn (vectors)
    (map (fn ((x . y)) (cons y x)) vectors)))

(define invert-x
  (fn (cols)
    (fn (vectors)
      (map (fn ((x . y)) (cons (- cols x 1) y)) vectors))))

(define random-transform
  (let ((transform (fn (t v) (if (= (rand 0 2) 1) (t v) v))))
    (fn (T1 T2 T3 vector)
      (transform T3 (transform T2 (transform T1 vector))))))

;;; grid generator ;;;

(define deduce-grid-size
  ; finds the biggest numbers in the list of coordinates
  (fn (vectors)
    (cons (+ (first (sort! (map first vectors) -)) 1)
          (+ (first (sort! (map rest vectors) -)) 1))))

(define enumerate-integers
  ; creates a list of integers from low to high, inclusive
  (fn (low high)
    (if (> low high)
      ()
      (cons low (enumerate-integers (+ low 1) high)))))

(define enumerate-grid-intervals
  ; creates a list with specified number of equal intervals
  (fn (index width)
    (let ((i (- index 1)))
      (if (< i 0)
        ()
        (cons (cons (* i width) (* index width))
              (enumerate-grid-intervals i width))))))

(define enumerate-grid-effects
  ; applies effects to each list element corresponding to each grid panel
  (fn (fx dur% coords cues)
    (if (or (= coords ()) (= cues ()))
      ()
      (cons (fx dur% (first coords) (first cues))
            (enumerate-grid-effects fx dur% (rest coords) (rest cues))))))

(define make-grid-effects
  (fn (fx vectors)
    (let (((cols . rows) (deduce-grid-size vectors))
          (gridsize (* cols rows))
          (thecols (reverse (enumerate-grid-intervals cols (/ cols))))
          (therows (reverse (enumerate-grid-intervals rows (/ rows))))
          (indices (enumerate-integers 0 (- gridsize 1)))

          ; converts grid vectors to normalized coordinates
          (coords-fn (fn ((x . y))
                       (let (((x0 . x1) (nth x thecols))
                             ((y0 . y1) (nth y therows)))
                         (list x0 y0 x1 y1))))
          ; determine the "effect trail" duration per grid panel
          (dur% (- 0.6 (* 0.05 rows)))  ; where rows={2,3,4,5,6,7,8}
          ; calculate progress cue point for a grid panel to show up
          (cue-fn (fn (idx) (* (/ (- 1.0 dur%) (- gridsize 1)) idx)))
          ; transorm vectors: reversed, transposed and/or laterally inverted
          (vectors# (random-transform reverse
                                      (invert-x cols)
                                      transpose-xy
                                      vectors)))
      
      ; apply effect to each of the grid panels
      (enumerate-grid-effects fx dur%
                              (map coords-fn vectors#)
                              (map cue-fn indices)))))

;;; grid effects ;;;

(define texture-subset-fx
  (fn (x0 y0 x1 y1)
    (effect "TextureSubset" (A)
            (param "x0" x0)
            (param "y0" y0)
            (param "x1" x1)
            (param "y1" y1))))

(define fade-in-fx
  (fn (p1 p2)
    (effect "Alpha" (A)
            (param "Alpha" 0.0 (at p1 0.0) (linear p2 1.0)))))

(define slide-in-fx
  (fn (p1 p2)
    (let ((axis   (if (= (rand 2) 0) "x" "y"))
          (offset (if (= (rand 2) 0) -0.5 0.5)))
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.0 (at p1 0.0) (linear p2 1.0)))
        (effect "Translate" (A)
                (param axis offset (at p1 offset) (linear p2 0.0)))))))

(define fade-to-white-tx
  (fn (p1 p2)
    (let ((mid (* (+ p1 p2) 0.5)))
      (layers (A B)
        ; show input A for first half of effect
        (effect "Alpha" ()
                (input 0 A)
                (param "Alpha" 1.0 (at mid 0.0)))
        ; show input B for second half of effect
        (effect "Alpha" ()
                (input 0 B)
                (param "Alpha" 0.0 (at mid 1.0)))
        ; white fade in and fade out
        ; (can't use ColorQuad here 'cos TextureSubset can't crop it)
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.001))
          (effect "Alpha" (A)
                  (param "Alpha" 0.0
                         (at p1 0.0)
                         (bezier mid 1.0 0.0 0.0)
                         (bezier p2  0.0 1.0 1.0)))
          (effect "Fit" (A))
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Lower)
                  (param "Path" (resource "white.jpg"))))))))

;;; grid effect helpers ;;;

(define per-grid-fade-in
  (fn (dur% coords cue)
    (list 'effect-stack
          (cons 'texture-subset-fx coords)
          (list 'with-inputs '(list A)
                (list 'fade-in-fx cue (+ cue dur%))))))

(define per-grid-slide-in
  (fn (dur% coords cue)
    (list 'effect-stack
          (cons 'texture-subset-fx coords)
          (list 'with-inputs '(list A)
                (list 'slide-in-fx cue (+ cue dur%))))))

(define per-grid-fade-to-white
  (fn (dur% coords cue)
    (list 'effect-stack
          (cons 'texture-subset-fx coords)
          (list 'with-inputs '(list A B)
                (list 'fade-to-white-tx cue (+ cue dur%))))))

;;; grid sequences ;;;;

; c = circular
; l = linear
; s = checkered spiral
; z = diagonal zigzag

(define c2x2
  (list (0 . 0) (0 . 1)
        (1 . 1) (1 . 0)))

(define s2x2
  (list (0 . 0) (1 . 1)
        (0 . 1) (1 . 0)))

(define z2x2
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (1 . 1)))

(define c3x3
  (list (0 . 0) (0 . 1) (0 . 2)
        (1 . 2) (2 . 2)
        (2 . 1) (2 . 0)
        (1 . 0)
        (1 . 1)))

(define l3x3
  (list (0 . 0) (1 . 0) (2 . 0)
        (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2)))

(define s3x3
  (list (0 . 0) (0 . 2)
        (2 . 2) (2 . 0)
        (1 . 1)
        (0 . 1) (1 . 2)
        (2 . 1) (1 . 0)))

(define z3x3
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (2 . 1) (1 . 2)
        (2 . 2)))

(define c4x4
  (list (0 . 0) (0 . 1) (0 . 2) (0 . 3)
        (1 . 3) (2 . 3) (3 . 3)
        (3 . 2) (3 . 1) (3 . 0)
        (2 . 0) (1 . 0)
        (1 . 1) (1 . 2)
        (2 . 2)
        (2 . 1)))

(define l4x4
  (list (0 . 0) (1 . 0) (2 . 0) (3 . 0)
        (3 . 1) (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2)
        (3 . 3) (2 . 3) (1 . 3) (0 . 3)))

(define s4x4
  (list (0 . 0) (0 . 2) (1 . 3)
        (3 . 3) (3 . 1) (2 . 0)
        (1 . 1) (2 . 2)
        (1 . 2) (2 . 1)
        (0 . 1) (0 . 3) (2 . 3)
        (3 . 2) (3 . 0) (1 . 0)))

(define z4x4
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (3 . 0) (2 . 1) (1 . 2) (0 . 3)
        (1 . 3) (2 . 2) (3 . 1)
        (3 . 2) (2 . 3)
        (3 . 3)))

(define c5x5
  (list (0 . 0) (0 . 1) (0 . 2) (0 . 3) (0 . 4)
        (1 . 4) (2 . 4) (3 . 4) (4 . 4) 
        (4 . 3) (4 . 2) (4 . 1) (4 . 0)
        (3 . 0) (2 . 0) (1 . 0) 
        (1 . 1) (1 . 2) (1 . 3)
        (2 . 3) (3 . 3)
        (3 . 2) (3 . 1)
        (2 . 1)
        (2 . 2)))

(define l5x5
  (list (0 . 0) (1 . 0) (2 . 0) (3 . 0) (4 . 0)
        (4 . 1) (3 . 1) (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2) (4 . 2)
        (4 . 3) (3 . 3) (2 . 3) (1 . 3) (0 . 3)
        (0 . 4) (1 . 4) (2 . 4) (3 . 4) (4 . 4)))

(define s5x5
  (list (0 . 0) (0 . 2) (0 . 4) (2 . 4)
        (4 . 4) (4 . 2) (4 . 0) (2 . 0)
        (1 . 1) (1 . 3)
        (3 . 3) (3 . 1)
        (2 . 2)
        (1 . 2) (2 . 3)
        (3 . 2) (2 . 1)
        (0 . 1) (0 . 3) (1 . 4) (3 . 4)
        (4 . 3) (4 . 1) (3 . 0) (1 . 0)))

(define z5x5
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (3 . 0) (2 . 1) (1 . 2) (0 . 3)
        (0 . 4) (1 . 3) (2 . 2) (3 . 1) (4 . 0)
        (4 . 1) (3 . 2) (2 . 3) (1 . 4)
        (2 . 4) (3 . 3) (4 . 2)
        (4 . 3) (3 . 4)
        (4 . 4)))

(define c6x6
  (list (0 . 0) (0 . 1) (0 . 2) (0 . 3) (0 . 4) (0 . 5)
        (1 . 5) (2 . 5) (3 . 5) (4 . 5) (5 . 5)
        (5 . 4) (5 . 3) (5 . 2) (5 . 1) (5 . 0)
        (4 . 0) (3 . 0) (2 . 0) (1 . 0)
        (1 . 1) (1 . 2) (1 . 3) (1 . 4)
        (2 . 4) (3 . 4) (4 . 4)
        (4 . 3) (4 . 2) (4 . 1)
        (3 . 1) (2 . 1)
        (2 . 2) (2 . 3)
        (3 . 3)
        (3 . 2)))

(define l6x6
  (list (0 . 0) (1 . 0) (2 . 0) (3 . 0) (4 . 0) (5 . 0) 
        (5 . 1) (4 . 1) (3 . 1) (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2) (4 . 2) (5 . 2) 
        (5 . 3) (4 . 3) (3 . 3) (2 . 3) (1 . 3) (0 . 3)
        (0 . 4) (1 . 4) (2 . 4) (3 . 4) (4 . 4) (5 . 4) 
        (5 . 5) (4 . 5) (3 . 5) (2 . 5) (1 . 5) (0 . 5)))

(define s6x6
  (list (0 . 0) (0 . 2) (0 . 4) (1 . 5) (3 . 5)
        (5 . 5) (5 . 3) (5 . 1) (4 . 0) (2 . 0)
        (1 . 1) (1 . 3) (2 . 4)
        (4 . 4) (4 . 2) (3 . 1)
        (2 . 2) (3 . 3)
        (2 . 3) (3 . 2)
        (1 . 2) (1 . 4) (3 . 4)
        (4 . 3) (4 . 1) (2 . 1)
        (0 . 1) (0 . 3) (0 . 5) (2 . 5) (4 . 5)
        (5 . 4) (5 . 2) (5 . 0) (3 . 0) (1 . 0)))

(define z6x6
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (3 . 0) (2 . 1) (1 . 2) (0 . 3)
        (0 . 4) (1 . 3) (2 . 2) (3 . 1) (4 . 0)
        (5 . 0) (4 . 1) (3 . 2) (2 . 3) (1 . 4) (0 . 5)
        (1 . 5) (2 . 4) (3 . 3) (4 . 2) (5 . 1)
        (5 . 2) (4 . 3) (3 . 4) (2 . 5)
        (3 . 5) (4 . 4) (5 . 3)
        (5 . 4) (4 . 5)
        (5 . 5)))

(define c7x7
  (list (0 . 0) (0 . 1) (0 . 2) (0 . 3) (0 . 4) (0 . 5) (0 . 6)
        (1 . 6) (2 . 6) (3 . 6) (4 . 6) (5 . 6) (6 . 6)
        (6 . 5) (6 . 4) (6 . 3) (6 . 2) (6 . 1) (6 . 0)
        (5 . 0) (4 . 0) (3 . 0) (2 . 0) (1 . 0)
        (1 . 1) (1 . 2) (1 . 3) (1 . 4) (1 . 5)
        (2 . 5) (3 . 5) (4 . 5) (5 . 5)
        (5 . 4) (5 . 3) (5 . 2) (5 . 1)
        (4 . 1) (3 . 1) (2 . 1)
        (2 . 2) (2 . 3) (2 . 4)
        (3 . 4) (4 . 4)
        (4 . 3) (4 . 2)
        (3 . 2)
        (3 . 3)))

(define l7x7
  (list (0 . 0) (1 . 0) (2 . 0) (3 . 0) (4 . 0) (5 . 0) (6 . 0)
        (6 . 1) (5 . 1) (4 . 1) (3 . 1) (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2) (4 . 2) (5 . 2) (6 . 2) 
        (6 . 3) (5 . 3) (4 . 3) (3 . 3) (2 . 3) (1 . 3) (0 . 3)
        (0 . 4) (1 . 4) (2 . 4) (3 . 4) (4 . 4) (5 . 4) (6 . 4) 
        (6 . 5) (5 . 5) (4 . 5) (3 . 5) (2 . 5) (1 . 5) (0 . 5)
        (0 . 6) (1 . 6) (2 . 6) (3 . 6) (4 . 6) (5 . 6) (6 . 6)))

(define s7x7
  (list (0 . 0) (0 . 2) (0 . 4) (0 . 6) (2 . 6) (4 . 6)
        (6 . 6) (6 . 4) (6 . 2) (6 . 0) (4 . 0) (2 . 0)
        (1 . 1) (1 . 3) (1 . 5) (3 . 5)
        (5 . 5) (5 . 3) (5 . 1) (3 . 1)
        (2 . 2) (2 . 4)
        (4 . 4) (4 . 2)
        (3 . 3)
        (2 . 3) (3 . 4)
        (4 . 3) (3 . 2)
        (1 . 2) (1 . 4) (2 . 5) (4 . 5)
        (5 . 4) (5 . 2) (4 . 1) (2 . 1)
        (0 . 1) (0 . 3) (0 . 5) (1 . 6) (3 . 6) (5 . 6)
        (6 . 5) (6 . 3) (6 . 1) (5 . 0) (3 . 0) (1 . 0)))

(define z7x7
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (3 . 0) (2 . 1) (1 . 2) (0 . 3)
        (0 . 4) (1 . 3) (2 . 2) (3 . 1) (4 . 0)
        (5 . 0) (4 . 1) (3 . 2) (2 . 3) (1 . 4) (0 . 5)
        (0 . 6) (1 . 5) (2 . 4) (3 . 3) (4 . 2) (5 . 1) (6 . 0)
        (6 . 1) (5 . 2) (4 . 3) (3 . 4) (2 . 5) (1 . 6)
        (2 . 6) (3 . 5) (4 . 4) (5 . 3) (6 . 2)
        (6 . 3) (5 . 4) (4 . 5) (3 . 6)
        (4 . 6) (5 . 5) (6 . 4)
        (6 . 5) (5 . 6)
        (6 . 6)))

(define c8x8
  (list (0 . 0) (0 . 1) (0 . 2) (0 . 3) (0 . 4) (0 . 5) (0 . 6) (0 . 7)
        (1 . 7) (2 . 7) (3 . 7) (4 . 7) (5 . 7) (6 . 7) (7 . 7)
        (7 . 6) (7 . 5) (7 . 4) (7 . 3) (7 . 2) (7 . 1) (7 . 0)
        (6 . 0) (5 . 0) (4 . 0) (3 . 0) (2 . 0) (1 . 0)
        (1 . 1) (1 . 2) (1 . 3) (1 . 4) (1 . 5) (1 . 6)
        (2 . 6) (3 . 6) (4 . 6) (5 . 6) (6 . 6)
        (6 . 5) (6 . 4) (6 . 3) (6 . 2) (6 . 1)
        (5 . 1) (4 . 1) (3 . 1) (2 . 1)
        (2 . 2) (2 . 3) (2 . 4) (2 . 5)
        (3 . 5) (4 . 5) (5 . 5)
        (5 . 4) (5 . 3) (5 . 2)
        (4 . 2) (3 . 2)
        (3 . 3) (3 . 4)
        (4 . 4)
        (4 . 3)))

(define l8x8
  (list (0 . 0) (1 . 0) (2 . 0) (3 . 0) (4 . 0) (5 . 0) (6 . 0) (7 . 0)
        (7 . 1) (6 . 1) (5 . 1) (4 . 1) (3 . 1) (2 . 1) (1 . 1) (0 . 1)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2) (4 . 2) (5 . 2) (6 . 2) (7 . 2)
        (7 . 3) (6 . 3) (5 . 3) (4 . 3) (3 . 3) (2 . 3) (1 . 3) (0 . 3)
        (0 . 4) (1 . 4) (2 . 4) (3 . 4) (4 . 4) (5 . 4) (6 . 4) (7 . 4)
        (7 . 5) (6 . 5) (5 . 5) (4 . 5) (3 . 5) (2 . 5) (1 . 5) (0 . 5)
        (0 . 6) (1 . 6) (2 . 6) (3 . 6) (4 . 6) (5 . 6) (6 . 6) (7 . 6)
        (7 . 7) (6 . 7) (5 . 7) (4 . 7) (3 . 7) (2 . 7) (1 . 7) (0 . 7)))

(define s8x8
  (list (0 . 0) (0 . 2) (0 . 4) (0 . 6) (1 . 7) (3 . 7) (5 . 7)
        (7 . 7) (7 . 5) (7 . 3) (7 . 1) (6 . 0) (4 . 0) (2 . 0)
        (1 . 1) (1 . 3) (1 . 5) (2 . 6) (4 . 6)
        (6 . 6) (6 . 4) (6 . 2) (5 . 1) (3 . 1)
        (2 . 2) (2 . 4) (3 . 5)
        (5 . 5) (5 . 3) (4 . 2)
        (3 . 3) (4 . 4)
        (3 . 4) (4 . 3)
        (2 . 3) (2 . 5) (4 . 5)
        (5 . 4) (5 . 2) (3 . 2)
        (1 . 2) (1 . 4) (1 . 6) (3 . 6) (5 . 6)
        (6 . 5) (6 . 3) (6 . 1) (4 . 1) (2 . 1)
        (0 . 1) (0 . 3) (0 . 5) (0 . 7) (2 . 7) (4 . 7) (6 . 7)
        (7 . 6) (7 . 4) (7 . 2) (7 . 0) (5 . 0) (3 . 0) (1 . 0)))

(define z8x8
  (list (0 . 0)
        (1 . 0) (0 . 1)
        (0 . 2) (1 . 1) (2 . 0)
        (3 . 0) (2 . 1) (1 . 2) (0 . 3)
        (0 . 4) (1 . 3) (2 . 2) (3 . 1) (4 . 0)
        (5 . 0) (4 . 1) (3 . 2) (2 . 3) (1 . 4) (0 . 5)
        (0 . 6) (1 . 5) (2 . 4) (3 . 3) (4 . 2) (5 . 1) (6 . 0)
        (7 . 0) (6 . 1) (5 . 2) (4 . 3) (3 . 4) (2 . 5) (1 . 6) (0 . 7)
        (1 . 7) (2 . 6) (3 . 5) (4 . 4) (5 . 3) (6 . 2) (7 . 1)
        (7 . 2) (6 . 3) (5 . 4) (4 . 5) (3 . 6) (2 . 7)
        (3 . 7) (4 . 6) (5 . 5) (6 . 4) (7 . 3)
        (7 . 4) (6 . 5) (5 . 6) (4 . 7)
        (5 . 7) (6 . 6) (7 . 5)
        (7 . 6) (6 . 7)
        (7 . 7)))

(define grid-sequence-tc
  (step-tc 1 '(l8x8 c8x8 z8x8 s8x8)
           2 '(l6x6 z6x6 c6x6 s6x6 l7x7 c7x7 z7x7 s7x7)
           3 '(l5x5 c5x5 z5x5 s5x5)
           4 '(l3x3 c3x3 z3x3 s3x3 l4x4 c4x4 z4x4 s4x4)
           5 '(c2x2 z2x2 s2x2)))

(define grid-sequence
  (let ((seq$ (apply shuffled-sequence (grid-sequence-tc SQUARE_SIZE))))
    (fn args (eval (seq$)))))  ; delayed evaluation


;-----------------------------------------------------------
;   Global effects

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))

(define muvee-global-effect view-fx)


;-----------------------------------------------------------
;   Segment effects
;   - captions
;   - grid

(define bright-grayscale-fpstr "!!ARBfp1.0
PARAM luma = { 0.299, 0.587, 0.114, 1.0 };
TEMP texfrag, gray;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MUL texfrag.a, texfrag.a, fragment.color.a;
DP3 gray.r, texfrag, luma;
MUL gray.r, gray.r, 1.5;
MOV gray.a, texfrag.a;
SWZ result.color, gray, r,r,r,a;
END")

(define grayscale-back-fx
  (effect-stack
    (effect "Translate" (A)
            (param "z" -0.002))
    (effect "Scale" (A)
            (param "x" 1.5)
            (param "y" 1.5))
    (effect "FragmentProgram" (A)
            (param "GlobalMode" 0)
            (param "ProgramString" bright-grayscale-fpstr))))

(define grid-layers
  (fn (fx seq)
    (eval (apply layers
                 (append! (list '(A))
                          (list '(with-inputs (list A) grayscale-back-fx))
                          (make-grid-effects fx seq))))))

(define per-grid-sequence
  (random-sequence per-grid-slide-in
                   per-grid-fade-in))

(define grid-fx
  (fn (start stop inputs)
    (let ((s (segment-index))
          (pure-start (+ (if (> s 0)
                           (segment-stop-time (- s 1))
                           start)
                         0.001))
          (pure-stop  (- (if (< s muvee-last-segment-index)
                           (segment-start-time (+ s 1))
                           stop)
                         0.001))
          (grid-stop  (* (+ pure-start pure-stop) 0.5))
          ; segment grid effect against grayscale background
          (grayback (grayscale-back-fx start pure-start inputs))
          (grid (grid-layers (per-grid-sequence) (grid-sequence)))
          (grid+gray (grid pure-start grid-stop (list grayback))))

      ; to prevent segment grids from wiping in too fast,
      ; limit the duration to a minimum of 0.5 seconds,
      ; otherwise don't use the grid effect
      (when (> (- grid-stop pure-start) 0.5) grid+gray))))

(define segment-effect-sequence
  (effect-selector
    (looping-sequence blank
                      blank
                      blank
                      blank
                      grid-fx
                      grid-fx
                      blank
                      blank)))

(define muvee-segment-effect
  (effect-stack
    segment-effect-sequence
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - dissolve
;   - blur
;   - fade-to-white
;   - fancy flip
;   - grid wipe

(define dissolve-tx
  (effect "CrossFade" (A B)))

(define blur-tx
  (let ((maxblur 5.0))
    (layers (A B)
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "Blur" ()
                (input 0 A)
                (param "Amount" 0.0
                       (linear 1.0 maxblur))))
      (effect-stack
        (effect "Alpha" (B)
                (param "Alpha" 0.0
                       (linear 1.0 1.0)))
        (effect "Blur" ()
                (input 0 B)
                (param "Amount" maxblur
                       (linear 1.0 0.0)))))))

(define flip-tx
  (fn (input axis pattern)
    (let ((n (- 6 SQUARE_SIZE)))
      (effect "Flip" (A)
              (param "Input" input)
              (param "Pattern" pattern)
              (when (= pattern 1)
                (do
                  (param "NumPolygons" (* n n 20))
                  (param "PolygonLength" (/ n))
                  (param "PolygonDistance" 4.0)))
              (when (!= pattern 0)
                (param "RotateAxis" axis))))))

(define fancy-flip-tx
  (effect-selector
    (fn args
      (let ((axis (rand 0 2))
            (pattern (rand 0 3)))
        (layers (A B)
          ; white background
          (effect-stack
            (effect "Translate" (A)
                    (param "z" -3.0))
            (effect "Scale" (A)
                    (param "x" 2.25)
                    (param "y" 2.25))
            (effect "ColorQuad" ()
                    (input 0 A)))
          ; flip A
          (with-inputs (list A) (flip-tx 0 axis pattern))
          ; flip B
          (with-inputs (list B) (flip-tx 1 axis pattern)))))))

(define grid-wipe-layers
  (fn (tx seq)
    (eval (apply layers
                 (append! (list '(A B))
                          (make-grid-effects tx seq))))))

(define grid-wipe-tx
  (effect-selector
    (fn args
      (grid-wipe-layers per-grid-fade-to-white (grid-sequence)))))

(define fade-to-white-0to1-tx
  (fade-to-white-tx 0.0 1.0))

(define muvee-transition
  (effect-selector
    (looping-sequence fade-to-white-0to1-tx
                      grid-wipe-tx
                      grid-wipe-tx
                      dissolve-tx
                      fade-to-white-0to1-tx
                      fade-to-white-0to1-tx
                      blur-tx
                      fancy-flip-tx)))


;-----------------------------------------------------------
;   Title and credits

(title-section
  (audio-clip "squares.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (foreground
    (fx view-fx))
  (text
    (align 'center 'center)
    (color 0 0 0)
    (fade-in)
    (font "-32,0,0,0,800,0,0,0,0,3,2,1,34,Tahoma")
    (layout (0.10 0.10) (0.90 0.90))))

(credits-section
  (audio-clip "squares.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (foreground
    (fx view-fx))
  (text
    (align 'center 'center)
    (color 0 0 0)
    (fade-in)
    (font "-22,0,0,0,800,0,0,0,0,3,2,1,34,Tahoma")
    (layout (0.10 0.10) (0.90 0.90))))

;;; transitions between title/credits and body ;;;

(muvee-title-body-transition dissolve-tx 2.0)

(muvee-body-credits-transition dissolve-tx 2.0)
