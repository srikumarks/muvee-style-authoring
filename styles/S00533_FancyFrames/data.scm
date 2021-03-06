;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00533_FancyFrames
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (one-of-many		THEME		Rays	(Rays  Crayons  Skies  Stage  None))
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

(define anim-rotate-z
  (fn ((rz0 rz1 rz2) (p1 p2))
    (effect "Rotate" (A)
            (param "ez" 1.0)
            (param "degrees" rz0 (smoove-linear-smoove 0.0 rz0 p1 rz1 p2 rz1 1.0 rz2) 30))))

(define anim-scale-xy
  (fn (((sx0 . sy0) (sx1 . sy1) (sx2 . sy2)) (p1 p2))
    (effect "Scale" (A)
            (param "x" sx0 (smoove-linear-smoove 0.0 sx0 p1 sx1 p2 sx1 1.0 sx2) 30)
            (param "y" sy0 (smoove-linear-smoove 0.0 sy0 p1 sy1 p2 sy1 1.0 sy2) 30))))

(define anim-scale-xy-norm
  (fn (((sx0 . sy0) (sx1 . sy1) (sx2 . sy2)) (p1 p2))
    (effect "Scale" (A)
            (param "x" sx0 (smoove-linear-smoove 0.0 (/ sx0 sx1) p1 1.0 p2 1.0 1.0 (/ sx2 sx1)) 30)
            (param "y" sy0 (smoove-linear-smoove 0.0 (/ sy0 sy1) p1 1.0 p2 1.0 1.0 (/ sy2 sy1)) 30))))

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

(define centerstage-img
  (format (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) "4-3" "16-9")
          "_background04.jpg"))

(define video-loop-fx
  (if (= THEME 'Stage)
    ; Stage background is an image
    (fn (start stop inputs)
      (mes:image (resource centerstage-img) render-aspect-ratio start stop))
    ; Rays/Crayons/Skies backgrounds are videos
    (let (((vid . dur) (case THEME
                         ('Skies   (cons "background03.wmv" 10.0))
                         ('Crayons (cons "background02.wmv" 15.0))
                         (_        (cons "background01.wmv" 32.0)))))
      (fn (start stop inputs)
        (video-loop-track (resource vid) 16/9
                          start stop 0.0 dur
                          2.0 dissolve-tx
                          ())))))

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

(define constant-slow-hover-fx
  (let ((hover-fn (fn (amplitude ang-freq)
                    (fn (p)
                      (* (sin (* ang-freq muvee-duration-secs p))
                         0.2 VARIATION amplitude)))))
    (effect-stack
      (effect "Translate" (A)
              (param "z" -1.0))
      (effect "Rotate" (A)
              (param "ex" 1.0)
              (param "degrees" 0.0 (hover-fn  8.0 0.5)))
      (effect "Rotate" (A)
              (param "ey" 1.0)
              (param "degrees" 0.0 (hover-fn 22.0 0.7)))
      (effect "Rotate" (A)
              (param "ez" 1.0)
              (param "degrees" 0.0 (hover-fn  5.0 0.3)))
      (effect "Translate" (A)
              (param "z" 1.0)))))

(define muvee-global-effect
  (effect-stack
    background-fx
    constant-slow-hover-fx))


;-----------------------------------------------------------
;   Segment effects
;   - frame with border
;   - frame morph
;   - captions in front of the input

;;; frame ;;;

(define bounded-segment-index
  (fn args
    (if (and args (first args))
      ((limiter 0 muvee-last-segment-index) (first args))
      (segment-index))))

(define crop-aspect-ratio
  (fn args
    (let ((s (bounded-segment-index (first args))))
      (cond
        ; non-magicSpotted image
        ((= (first (source-rectangles s)) 'auto)
         (source-aspect-ratio s))
        ; magicSpotted image
        ((= (first (source-rectangles s)) 'manual)
         render-aspect-ratio)
        ; wide input video, narrow output frame
        ; (e.g. 16:9 input, 4:3 output)
        ((>= (source-aspect-ratio s) (+ render-aspect-ratio 0.001))
         render-aspect-ratio)
        ; narrow input video, wide output frame
        ; (e.g. 4:3 input, 16:9 output)
        (_  (source-aspect-ratio s))))))

(define xy-stretch-fit-to-source
  (fn (factor . args)
    (let ((s (bounded-segment-index (first args))))
      (case (source-type s)
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
        (_ (cons 1.0 1.0))))))

(define xy-stretch-factors
  (fn (segment-index)
    (let ((screen-aspect-ratio (crop-aspect-ratio segment-index))
          (factor (/ screen-aspect-ratio render-aspect-ratio))
          ((x . y) (xy-stretch-fit-to-source factor segment-index))
          ; make constant-width border regardless of:
          ; - content's edge (left, right, top, bottom)
          ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
          ; - render aspect ratio (4:3 or 16:9)
          (b 0.06)
          (b+ (if (> factor 1.0) (* b factor) b))
          (x+ (* x (+ 1.0 (/ b+ screen-aspect-ratio))))
          (y+ (* y (+ 1.0 b+))))
      ; return the stretch factors
      (cons (cons x y) (cons x+ y+)))))

;;; frame morph ;;;

(define hash
  (let ((ht (mk-hashtable)))
    (fn kv-pair (apply ht kv-pair))))

(define make-anim-params
  (fn (params (p1 p2))
    (list (if (< p1 0.001) (nth 1 params) (nth 0 params))
          (nth 1 params)
          (if (> p2 0.999) (nth 1 params) (nth 2 params)))))

(define make-anim-rotation-params
  (fn (axis base p1p2)
    (let ((ht (if (hash axis) (hash axis) (cons 0.0 0.0)))
          (n0 (first ht))  ; retrieve previous pair
          (n1 (rest ht))   ; of values from hashtable
          (n2 (* (rand (- base) base) VARIATION)))
      ; store next pair of values to hashtable
      (hash axis (cons n1 n2))
      ; make params
      (make-anim-params (list n0 n1 n2) p1p2))))

(define make-anim-scale-xy-params
  (fn (seg p1p2)
    (let ((f (xy-stretch-factors 0))
          (ht (if (hash 'xy) (hash 'xy) (cons f f)))
          (xy0 (first ht))  ; retrieve previous pair
          (xy1 (rest ht))   ; of values from hashtable
          (xy2 (xy-stretch-factors (+ seg 1))))
      ; store next pair of values to hashtable
      (hash 'xy (cons xy1 xy2))
      ; make params
      (make-anim-params (list xy0 xy1 xy2) p1p2))))

(define make-anim-opacity-params
  (fn (base p1p2)
    (make-anim-params (list 0.0 base 0.0) p1p2)))

(define pseudo-transition-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(define frame-morph-generic
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
            (rz (make-anim-rotation-params 'rz 10.0 p1p2))
            (op (make-anim-opacity-params 0.999 p1p2))
            (xy (make-anim-scale-xy-params s p1p2)))
        ; frame morph
        (effect-stack
          ; positioning
          (anim-rotate-z rz p1p2)
          (anim-opacity  op p1p2)
          ; content
          (layers (A)
            ; border
            (effect-stack
              (anim-scale-xy (map rest xy) p1p2)
              (effect "ColorQuad" ()
                      (param "a" (* TRANSPARENCY TRANSPARENCY))))
            ; user's media
            (effect-stack
              (anim-scale-xy-norm (map first xy) p1p2)
              (effect "Translate" ()
                      (input 0 A)
                      (param "z" 0.005)))
            ; user's captions
            (effect-stack
              (effect "Translate" (A)
                      (param "z" 0.010))
              muvee-segment-captions)))))))

(define frame-morph-fx
  (fn (p1 p2)
    (effect-selector (frame-morph-generic p1 p2))))

;;; segment effect ;;;

(define muvee-segment-effect
  (frame-morph-fx () ()))


;-----------------------------------------------------------
;   Title and credits

(define BACKGROUND_VIDEO
  (format "titlecredits"
          (case THEME
            ('Skies   "03")
            ('Crayons "02")
            (_        "01"))
          ".wmv"))

(title-section
  (cond
    ((= THEME 'Stage) (background (image centerstage-img)))
    ((= THEME 'None)  (background (color 0 0 0)))
    ((!= THEME 'None) (background (video BACKGROUND_VIDEO))))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-out)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Verdana")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (cond
    ((= THEME 'Stage) (background (image centerstage-img)))
    ((= THEME 'None)  (background (color 0 0 0)))
    ((!= THEME 'None) (background (video BACKGROUND_VIDEO))))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-in)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Verdana")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(muvee-title-body-transition dissolve-tx pseudo-transition-dur)

(muvee-body-credits-transition dissolve-tx pseudo-transition-dur)
