;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00534_Mystical
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (one-of-many		THEME		Snow	(Cubes  Flies  Snow  None))
  (one-of-few		DIRECTION	Reverse	(Reverse  Forward))
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	VARIATION	0.5	0.0  1.0)
  (continuous-slider	TRANSPARENCY	0.5	0.0  1.0))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED 0.5 0.9)


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
;   Transitions
;   - dissolve

(define dissolve-tx
  (let ((a 2.5))
    (layers (A B)
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.001))
        (effect "Alpha" ()
                (input 0 B)
                (param "Alpha" 0.0
                       (fn (p) (- 1.0 (pow (- 1.0 p) a))))))
      (effect "Alpha" ()
              (input 0 A)
              (param "Alpha" 1.0
                     (fn (p) (- 1.0 (pow p a))))))))

(define muvee-transition dissolve-tx)


;-----------------------------------------------------------
;   Global effects
;   - looping background video
;   - volumetric lights triggered on flash hints

(define video-loop-fx
  (let (((vid . dur) (case THEME
                       ('Flies (cons "background05.wmv" 19.0))
                       ('Cubes (cons "background06.wmv" 10.0))
                       (_      (cons "background07.wmv" 10.0)))))
    (fn (start stop inputs)
      (video-loop-track (resource vid) 16/9
                        start stop 0.0 dur
                        2.0 dissolve-tx
                        ()))))

(define background-fx
  (let ((delta-z -30.0)
        (fovy 45.0)
        (tangent (tan (deg->rad (* fovy 0.5))))
        (scale (- 1.0 (* tangent delta-z)))
        (zfar (- (/ tangent) delta-z)))
    (effect-stack
      (effect "CropMedia" (A))
      (effect "Perspective" (A)
              (param "fovy" fovy)
              (param "zFar" zfar))
      (layers (A)
        (if (= THEME 'None)
          ; no background
          (fn args)
          ; background video
          (effect-stack
            (effect "Translate" (A)
                    (param "z" delta-z))
            (effect "Scale" (A)
                    (param "x" scale)
                    (param "y" scale))
            video-loop-fx))
        ; foreground
        (effect "Translate" ()
                (input 0 A)
                (param "z" -1.0))))))

;;; triggered lights ;;;

(define volumetric-light-fx
  (effect@flash-hints
    60
    4.0
    (triggered-effect
      (- time 0.05)
      (+ time 2.95)
      (effect "VolumetricLights" (A)
              (param "NumberOfLayers" 12)
              (param "TextureIncrement" 0.01)
              (param "TranslateIncrement" 0.01)
              (param "AlphaDecay" 0.90)
              (param "Animation" value
                     (fn (p) (* (exp (* -5.0 p)) value)))))))

(define muvee-global-effect
  (effect-stack
    volumetric-light-fx
    background-fx))


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
  ; ranges from 0.5 to 2.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 1.5) 0.5))

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
;   Title and credits

(define BACKGROUND_VIDEO
  (format "titlecredits"
          (case THEME
            ('Flies "05")
            ('Cubes "06")
            (_      "07"))
          ".wmv"))

(title-section
  (if (= THEME 'None)
    (background (color 0 0 0))
    (background (video BACKGROUND_VIDEO)))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-out)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Verdana")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (if (= THEME 'None)
    (background (color 0 0 0))
    (background (video BACKGROUND_VIDEO)))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-in)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Verdana")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(muvee-title-body-transition (effect "CrossFade" (A B)) 0.5)

(muvee-body-credits-transition (effect "CrossFade" (A B)) 0.5)
