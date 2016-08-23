;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00512_Strips
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (discrete-slider	STRIPS		2	0  4)
  (one-of-few		THEME		Black	(Black  White)))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(segment-durations 4.0 2.0 2.0 4.0 2.0 2.0 6.0 2.0)

(segment-duration-tc 0.00 3.00
                     0.30 2.00
                     0.70 2.00
                     1.00 1.50)

(time-warp-tc 0.00 0.30
              0.25 0.75
              0.65 1.00
              1.00 1.00)

(preferred-transition-duration 2.5)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        1.00 1.00)


;-----------------------------------------------------------
;   Global effects
;   - background

(define background-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))
    (layers (A)
      ; background
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "ColorQuad" ()
                (param "a" (if (= THEME 'Black) 0.0 1.0))))
      ; foreground
      A)))

(define muvee-global-effect background-fx)


;-----------------------------------------------------------
;   Segment effects
;   - captions

(define muvee-segment-effect muvee-std-segment-captions)


;-----------------------------------------------------------
;   Transitions
;   - strips slide
;   - push with gap

;;; strips slide ;;;

(define (float= x y err) 
  (and (> x (- y err)) (< x (+ y err))))

(define horiz-dist
  (fn (dd)
    (let ((s (segment-index)))
      (if (and s
               (= (source-type (+ s 1)) 'video)
               (float= (source-aspect-ratio (+ s 1)) 4/3 0.001)
               (float= render-aspect-ratio 16/9 0.001))
        ; special case for 16:9 output:
        ; if next segment is a 4:3 video, move horizontally
        ; to snap to the left/right edge of the video,
        ; plus an additional 4/9(=16/9-4/3) units
        (if (< dd 0.0)
          (- (* dd 4/3) 4/9)
          (+ (* dd 4/3) 4/9))
        ; for other combinations of aspect ratios,
        ; just snap to the left/right edge of the video
        (* dd render-aspect-ratio)))))

(define slide-in-fx
  (fn (horiz? d t0 t1)
    (let (((axis . dist) (if horiz?
                           (cons "x" (horiz-dist (+ d d)))
                           (cons "y" (+ d d))))
          ((t0+ . t1-) (cons (+ t0 0.001) (- t1 0.001))))
      (effect "Translate" (A)
              (param "z" 0.001)
              (param axis dist
                     (at t0+ dist)
                     (linear t1- 0.0)
                     (linear 1.0 0.0))))))

(define texture-subset-fx
  (fn (x0 y0 x1 y1)
    (effect "TextureSubset" (A)
            (param "x0" x0)
            (param "y0" y0)
            (param "x1" x1)
            (param "y1" y1))))

(define strips-intervals
  (fn (index width salt x0)
    (let ((delta (* (rand (- width) width) salt 0.5))
          (i (- index 1))
          (x (if (< i 1) 0.0 (+ (* i width) delta))))
      (if (< i 0)
        ()
        (cons (cons x x0)
              (strips-intervals i width salt x))))))

(define strips-move-distances
  (fn (intervals reverse?)
    (let ((op (if reverse?
                (fn (n) (- 1.0 (first n)))
                (fn (n) (- (rest n))))))
      (map op intervals))))

(define strips-timings
  (fn (distances)
    (let ((total (apply + distances))
          (time (list 0.0)))
      (map (fn (n)
             (let ((t0 (first time))
                   (t1 (+ (/ n total) t0)))
               (setf! time t1)
               (cons t0 t1)))
           distances))))

(define strips-params
  (fn (intervals distances timings)
    (if (or (= intervals ()) (= distances ()) (= timings ()))
      ()
      (let ((((i0 . i1) . i*) intervals)
            (((t0 . t1) . t*) timings)
            ((d . d*) distances))
        (cons (list (list i0 i1) d (list t0 t1))
              (strips-params i* d* t*))))))

(define strips-slide-helper
  (fn (input dir num salt)
    (let ((horiz? (or (= dir 'rtl) (= dir 'ltr)))
          (reverse? (or (= dir 'rtl) (= dir 'ttb)))
          (thestrips (strips-intervals num (/ num) salt 1.0))
          (intervals (if reverse? (reverse thestrips) thestrips))
          (distances (strips-move-distances intervals reverse?))
          (timings (strips-timings distances))
          (params (strips-params intervals distances timings)))
      (map (fn (((i0 i1) d (t0 t1)))
             (list 'with-inputs
                   (list 'list input)
                   (effect-stack
                     (slide-in-fx horiz? d t0 t1)
                     (if horiz?
                       (texture-subset-fx i0 0.0 i1 1.0)
                       (texture-subset-fx 0.0 i0 1.0 i1)))))
           params))))

(define fade-input0-to-background-fx
  (effect "Alpha" ()
          (input 0 A)
          (param "Alpha" 1.0
                 (bezier 1.0 0.0 0.0 0.0))))

(define strips-slide-tx
  (fn (dir num)
    (eval (apply layers
                 (append! (list '(A B) 'fade-input0-to-background-fx)
                          (strips-slide-helper 'B dir num 1.0))))))

(define strips-slide
  (let ((dir (random-sequence 'ltr 'ttb 'rtl 'btt))
        (num (pow 2 STRIPS)))
    (fn args
      (apply (strips-slide-tx (dir) num)
             args))))

;;; pushes ;;;

(define push+gap-tx
  (fn (dir border)
    ; 0=up, 1=down, 2=left, 3=right
    (let ((dir%4 (% dir 4))
          (units (if (or (= dir%4 1) (= dir%4 2)) -2.0 2.0))
          (space (* border units))
          ((axis . vec) (if (> dir%4 1)
                          (cons "x" (+ space (* units render-aspect-ratio)))
                          (cons "y" (+ space units))))
          (~vec (- vec)))
      (layers (A B)
        (effect "Translate" ()
                (input 0 A)
                (param axis 0.0
                       (bezier 1.0 vec 0.0 vec)))
        (effect "Translate" ()
                (input 0 B)
                (param axis ~vec
                       (bezier 1.0 0.0 ~vec 0.0)))))))

(define push
  (fn args
    (apply (push+gap-tx (rand 4) 0.1)
           args)))

;;; transition selection ;;;

(define muvee-transition
  (effect-selector
    (shuffled-sequence push
                       push
                       strips-slide
                       strips-slide)))


;-----------------------------------------------------------
;   Title and credits

(title-section
  (audio-clip "strips.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (text
    (align 'center 'center)
    (color 0 119 30)
    (font "-21,0,0,0,700,1,0,0,0,3,2,1,34,Tahoma")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (audio-clip "strips.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (text
    (align 'center 'center)
    (color 0 119 30)
    (font "-21,0,0,0,700,1,0,0,0,3,2,1,34,Tahoma")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define background+push+gap-tx
  (transition-stack background-fx (push+gap-tx 2 0.1)))

(muvee-title-body-transition background+push+gap-tx 2.0)

(muvee-body-credits-transition background+push+gap-tx 2.0)
