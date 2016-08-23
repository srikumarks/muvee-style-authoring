;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00520_Basic2
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (one-of-many		THEME		Flower	(Flower  Roses  Clouds  Stars  None))
  (one-of-few		DIRECTION	Forward	(Forward  Reverse))
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	VARIATION	0.0	0.0  1.0)
  (continuous-slider	TRANSPARENCY	0.5	0.0  1.0))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration 18.0) 4.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 1.50
                     1.00 0.40)

(time-warp-tc 0.00 0.50
              0.45 1.00
              1.00 1.00)

(define average-transition-duration-beats
  ; ranges between 1/4-beat and average-segment-duration
  (let ((min-duration 1.0)
        (max-duration average-segment-duration-beats))
    (+ (* (- max-duration min-duration)
          base-duration)
       min-duration)))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.50
                        1.00 0.40)


;-----------------------------------------------------------
;   Helper functions

(define gompertz-fn
  ; formula:
  ;   f(t) = e^( b * e^(c*t) )
  ; we require b < -8 and c < -8 so that the useful parts
  ; of the curve falls within the unit domain and range
  (fn (t)
    (exp (* (exp (* t -10.0)) -8.0))))

(define smoove
  ; sets up parameters for the gompertz curve so as to get
  ; "smooth-move" between a and b from progress p0 to p1
  (fn (p0 a p1 b)
    (let ((tc (linear-tc 0.0 0.0 p0 0.0 p1 1.0 1.0 1.0)))
      (fn (p)
        (+ (* (- b a) (gompertz-fn (tc p))) a)))))

(define smoove-linear-smoove
  ; "smooth-move" between a and b from progress p0 to p1,
  ; followed by linear move between b and c from p1 to p2,
  ; and "smooth-move" between c and d from progress p2 to p3,
  (fn (p0 a p1 b p2 c p3 d)
    (fn (p)
      (cond
        ((< p p1)  ((smoove p0 a p1 b) p))
        ((> p p2)  ((smoove p2 c p3 d) p))
        (_         ((linear-tc 0.0 b p1 b p2 c) p))))))

(define anim-rotate-x
  (fn ((rx0 rx1 rx2) (p1 p2))
    (effect "Rotate" (A)
            (param "ex" 1.0)
            (param "degrees" rx0 (smoove-linear-smoove 0.0 rx0 p1 rx1 p2 rx1 1.0 rx2) 30))))

(define anim-rotate-y
  (fn ((ry0 ry1 ry2) (p1 p2))
    (effect "Rotate" (A)
            (param "ey" 1.0)
            (param "degrees" ry0 (smoove-linear-smoove 0.0 ry0 p1 ry1 p2 ry1 1.0 ry2) 30))))

(define anim-rotate-z
  (fn ((rz0 rz1 rz2) (p1 p2))
    (effect "Rotate" (A)
            (param "ez" 1.0)
            (param "degrees" rz0 (smoove-linear-smoove 0.0 rz0 p1 rz1 p2 rz1 1.0 rz2) 30))))

(define anim-translate-xyz
  (fn ((tx0 tx1 tx2) (ty0 ty1 ty2) (tz0 tz1 tz2) (p1 p2))
    (effect "Translate" (A)
            (param "x" tx0 (smoove-linear-smoove 0.0 tx0 p1 tx1 p2 tx1 1.0 tx2) 30)
            (param "y" ty0 (smoove-linear-smoove 0.0 ty0 p1 ty1 p2 ty1 1.0 ty2) 30)
            (param "z" tz0 (smoove-linear-smoove 0.0 tz0 p1 tz1 p2 tz1 1.0 tz2) 30))))

(define anim-opacity
  (fn ((a0 a1 a2) (p1 p2))
    (effect "Alpha" (A)
            (param "Alpha" a0 (smoove-linear-smoove 0.0 a0 p1 a1 p2 a1 1.0 a2) 30))))


;-----------------------------------------------------------
;   Global effects
;   - slow rotating background

(define background-image
  (format "background"
          (case THEME
            ('Stars  "04")
            ('Clouds "03")
            ('Roses  "02")
            ('Flower "01")
            (_       ""))
          ".jpg"))

(define slow-rotate-fx
  (fn (speed)
    (effect-selector
      (fn (start stop inputs)
        (effect "Rotate" (A)
                (param "ez" 1.0)
                (param "degrees" 0.0
                       (fn (p) (* speed p (- stop start)))))))))

(define background-fx
  (fn (rotation-speed)
    (let ((delta-z -30.0)
          (fovy 45.0)
          (tangent (tan (deg->rad (* fovy 0.5))))
          (scale (- 1.0 (* tangent delta-z)))
          (zfar (- (/ tangent) delta-z))
          ; scale to fill
          (scale2 (sqrt (+ (* render-aspect-ratio render-aspect-ratio) 1.0))))
      (effect-stack
        (effect "CropMedia" (A))
        (effect "Perspective" (A)
                (param "fovy" fovy)
                (param "zFar" zfar))
        (layers (A)
          ; background
          (if (= THEME 'None)
            ; empty background
            (fn args)
            ; background image
            (effect-stack
              (effect "Translate" (A)
                      (param "z" delta-z))
              (effect "Scale" (A)
                      (param "x" (* scale scale2))
                      (param "y" (* scale scale2)))
              (slow-rotate-fx rotation-speed)
              (effect "PictureQuad" ()
                      (param "Quality" Quality_Higher)
                      (param "Path" (resource background-image)))))
          ; translate foreground behind by 1 unit
          (effect "Translate" ()
                  (input 0 A)
                  (param "z" -1.0)))))))

(define muvee-global-effect (background-fx -0.5))


;-----------------------------------------------------------
;   Segment effects
;   - frame with border
;   - zoom through
;   - captions in front of the input

;;; frame ;;;

(define crop-aspect-ratio
  (fn args
    (cond
      ; non-magicSpotted image
      ((= (first (source-rectangles)) 'auto)
       (source-aspect-ratio))
      ; magicSpotted image
      ((= (first (source-rectangles)) 'manual)
       render-aspect-ratio)
      ; wide input video, narrow output frame
      ; (e.g. 16:9 input, 4:3 output)
      ((>= (source-aspect-ratio) (+ render-aspect-ratio 0.001))
       render-aspect-ratio)
      ; narrow input video, wide output frame
      ; (e.g. 4:3 input, 16:9 output)
      (_  (source-aspect-ratio)))))

(define xy-stretch-fit-to-source
  (fn (factor)
    (case (source-type)
      ('image (if (> factor 1.0)
                ; if source is very long landscape image,
                ; inverse-scale y and maintain x,
                ; thus preserving aspect ratio
                (cons 1.0 (/ factor))
                ; for other types of images, just scale x
                (cons factor 1.0)))
      ('video (if (< factor 1.0)
                ; if source video is narrower than output frame
                ; (e.g. 4:3 input, 16:9 output), just scale x
                (cons factor 1.0)
                ; otherwise, no scaling is required
                (cons 1.0 1.0)))
      (_ (cons 1.0 1.0)))))

(define frame-contents-fx
  (layers (A)
    ; user's media behind border
    ; (required when the angle is more than 90 degrees,
    ; and that occurs when Angle Variation slider is set
    ; beyond the 75% mark, because 0.75 * 120 = 90)
    (if (> VARIATION 0.75)
      (effect "Translate" ()
              (input 0 A)
              (param "z" -0.005))
      (fn args))
    ; border
    (let ((screen-aspect-ratio (crop-aspect-ratio))
          (factor (/ screen-aspect-ratio render-aspect-ratio))
          ((x . y) (xy-stretch-fit-to-source factor))
          ; make constant-width border regardless of:
          ; - content's edge (left, right, top, bottom)
          ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
          ; - render aspect ratio (4:3 or 16:9)
          (b 0.06)
          (b+ (if (> factor 1.0) (* b factor) b))
          (x+ (* x (+ 1.0 (/ b+ screen-aspect-ratio))))
          (y+ (* y (+ 1.0 b+))))
      (effect-stack
        (effect "Scale" (A)
                (param "x" x+)
                (param "y" y+))
        (effect "ColorQuad" ()
                (param "a" (* TRANSPARENCY TRANSPARENCY)))))
    ; user's media
    (effect "Translate" ()
            (input 0 A)
            (param "z" 0.005))
    ; user's captions
    (effect-stack
      (effect "Translate" (A)
              (param "z" 0.010))
      muvee-segment-captions)))

;;; zoom ;;;

(define make-anim-params
  (fn (tuple (p1 p2))
    (let ((params (if (= DIRECTION 'Reverse) (reverse tuple) tuple)))
      (list (if (< p1 0.001) (nth 1 params) (nth 0 params))
            (nth 1 params)
            (if (> p2 0.999) (nth 1 params) (nth 2 params))))))

(define make-anim-rotation-params
  (fn (base p1p2)
    (let ((n (* (rand (- base) base) VARIATION)))
      (make-anim-params (list n (* n 0.1) (* n -0.4)) p1p2))))

(define make-anim-translation-params
  (fn (base p1p2)
    (let ((n (* (rand (- base) base) VARIATION)))
      (make-anim-params (list n 0.0 (* n -0.25)) p1p2))))

(define make-anim-zooming-params
  (fn (base p1p2)
    (make-anim-params (list (- base) 0.0 (* base 0.15)) p1p2)))

(define make-anim-opacity-params
  (fn (base p1p2)
    (make-anim-params (list 0.0 base 0.0) p1p2)))

(define pseudo-transition-dur
  (+ (* base-duration 3.0) 0.5))

(define zoom-through-generic
  (fn (set!p1 set!p2)
    (fn (start stop inputs)
      (let ((s (segment-index))
            (seg-dur (- stop start))
            (muveebody? (int? muvee-last-segment-index))
            (last-seg (if muveebody? muvee-last-segment-index -999))
            ; gets the start and stop times of the current non-overlapping
            ; "pure" segment, except for the first and last segment, where
            ; their "pure" start and stop times are derived based on
            ; pseudo-overlap duration
            (pure-start-time (if (> s 0)
                               (segment-stop-time (- s 1))
                               (+ start pseudo-transition-dur)))
            (pure-stop-time  (if (< s last-seg)
                               (segment-start-time (+ s 1))
                               (- stop pseudo-transition-dur)))
            ; [p1,p2] marks the progress interval
            ; where the user's clip is stationary
            (p1 (if set!p1 set!p1 (/ (- pure-start-time start) seg-dur)))
            (p2 (if set!p2 set!p2 (/ (- pure-stop-time  start) seg-dur)))
            (p1p2 (list p1 p2))
            ; make tuples of animated values (v0, v1, v2)
            ; such that effect parameters take:
            ; - v0 at start of effect (0% progress)
            ; - v1 between progress p1 and p2
            ; - v2 at end of effect (100% progress)
            (rx (make-anim-rotation-params 120.0 p1p2))
            (ry (make-anim-rotation-params 120.0 p1p2))
            (rz (make-anim-rotation-params 120.0 p1p2))
            (tx (make-anim-translation-params 4.0 p1p2))
            (ty (make-anim-translation-params 3.0 p1p2))
            (tz (make-anim-zooming-params 24.0 p1p2))
            (op (make-anim-opacity-params 0.999 p1p2)))
        ; zoom-through
        (effect-stack
          (anim-translate-xyz tx ty tz p1p2)
          (anim-rotate-x rx p1p2)
          (anim-rotate-y ry p1p2)
          (anim-rotate-z rz p1p2)
          (anim-opacity op p1p2))))))

(define zoom-through-fx
  (fn (p1 p2)
    (effect-selector (zoom-through-generic p1 p2))))

(define constant-slow-zoom-fx
  (effect-selector
    (fn (start stop inputs)
      (let ((v (if (= DIRECTION 'Reverse) -0.03 0.03))
            (d (* (- stop start) v)))
        (effect "Translate" (A)
                (param "z" (- d) (linear 1.0 d)))))))

;;; segment effect ;;;

(define muvee-segment-effect
  (effect-stack
    constant-slow-zoom-fx
    (zoom-through-fx () ())
    frame-contents-fx))


;-----------------------------------------------------------
;   Transitions
;   - dissolve

(define dissolve-tx
  (let ((a 2.5))
    (layers (A B)
      (effect "Alpha" ()
              (input 0 B)
              (param "Alpha" 0.0
                     (fn (p) (- 1.0 (pow (- 1.0 p) a)))))
      (effect "Alpha" ()
              (input 0 A)
              (param "Alpha" 1.0
                     (fn (p) (- 1.0 (pow p a))))))))

(define muvee-transition dissolve-tx)


;-----------------------------------------------------------
;   Title and credits

(define TITLE_FOREGROUND_FX
  (effect-stack
    (background-fx 0.0)
    constant-slow-zoom-fx
    (zoom-through-fx 0.0 ())))

(define CREDITS_FOREGROUND_FX
  (effect-stack
    (background-fx 0.0)
    constant-slow-zoom-fx
    (zoom-through-fx () 1.0)))

(define TEXT_COLOR
  (case THEME
    ('Stars  0xFFF200)
    ('Clouds 0x6DCFF6)
    ('Roses  0xFFFFFF)
    ('Flower 0xFF00FF)
    (_       0xFFFFFF)))

(define TITLE_TEXT_FONT
  (case THEME
    ('Stars  "-48,0,0,0,900,0,0,0,0,3,2,1,34,Courier New")
    ('Clouds "-52,0,0,0,400,1,0,0,0,3,2,1,34,Comic Sans MS")
    ('Roses  "-58,0,0,0,700,1,0,0,0,3,2,1,34,Palatino Linotype")
    ('Flower "-56,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")
    (_       "-52,0,0,0,700,1,0,0,0,3,2,1,34,Arial")))

(define CREDITS_TEXT_FONT
  (case THEME
    ('Stars  "-24,0,0,0,900,1,0,0,0,3,2,1,34,Courier New")
    ('Clouds "-28,0,0,0,400,1,0,0,0,3,2,1,34,Comic Sans MS")
    ('Roses  "-32,0,0,0,700,1,0,0,0,3,2,1,34,Palatino Linotype")
    ('Flower "-26,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")
    (_       "-28,0,0,0,700,1,0,0,0,3,2,1,34,Arial")))

(title-section
  (background
    (image "transparent.png"))
  (foreground
    (fx TITLE_FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color TEXT_COLOR)
    (font TITLE_TEXT_FONT)
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 1.0  dy: 1.0  size: 4.0)))

(credits-section
  (background
    (image "transparent.png"))
  (foreground
    (fx CREDITS_FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color TEXT_COLOR)
    (font CREDITS_TEXT_FONT)
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 1.0  dy: 1.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(muvee-title-body-transition dissolve-tx pseudo-transition-dur)

(muvee-body-credits-transition dissolve-tx pseudo-transition-dur)
