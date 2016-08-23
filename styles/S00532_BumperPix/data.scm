;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00532_BumperPix
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (one-of-few		DIRECTION	Both	(Both  Horiz  Vert))
  (one-of-few		BORDER		Black	(Black  White  None)))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED 0.5 0.055)


;-----------------------------------------------------------
;   Transitions
;   - dissolve
;   - collide and push

(define dissolve-tx
  (effect "CrossFade" (A B)))

(define bang-sfx
  (fn (p)
    (sound ((random-sequence "bump2.mvx" "bump2.mvx"))
           start: p
           mstop: 1.0
           volume: 3.0)))

(define collide-and-push-tx
  (fn (dir)
    (let ((seg-idx (segment-index))
          ((x0 y0 s0) (frame-content-params seg-idx))
          ((x1 y1 s1) (frame-content-params (+ seg-idx 1)))
          ; 0=up, 1=down, 2=left, 3=right
          (dir%4 (% dir 4))
          (units (* (if (or (= dir%4 1) (= dir%4 2)) -1.0 1.0)
                    (if (> dir%4 1) render-aspect-ratio 1.0)))          
          ; movement axis and vectors
          ((axis v0 v1) (if (> dir%4 1)
                          (list "x"
                                (* (+ (* x1 s1) 1.0) units)
                                (* (+ (* x1 s1) (* x0 s0)) units))
                          (list "y"
                                (* (+ (* y1 s1) 1.0) units)
                                (* (+ (* y1 s1) (* y0 s0)) units))))
          ; time progress of the collision
          (cxn (fabs (/ (- v0 v1) units 2))))
      (layers (A B)
        (effect "Translate" ()
                (input 0 A)
                (bang-sfx cxn)  ; insert collision sound effect
                (param "z" -0.001)
                (param axis 0.0
                       (at cxn 0.0)
                       (linear 1.0 (* -2.75 units))))
        (effect "Translate" ()
                (input 0 B)
                (param axis v0
                       (linear cxn v1)
                       (bezier 1.0 0.0 0.0 0.0)))))))

(define direction
  (let ((dir (case DIRECTION
               ('Vert  (list 0 1 0 1))
               ('Horiz (list 2 3 2 3))
               (_      (list 0 1 2 3)))))
    (apply shuffled-sequence dir)))

(define collide-with-next-frame
  (effect-selector
    (fn args (collide-and-push-tx (direction)))))

(define muvee-transition collide-with-next-frame)


;-----------------------------------------------------------
;   Global effects
;   - looping background video

(define background-images
  (apply looping-sequence
         (map (fn (f) (resource (format "background" f ".jpg")))
              (list "01" "02" "03"))))

(define (image-loop-track aspect-ratio start stop duration overlap tx trk)
  (if (< start (- stop overlap))
    (image-loop-track aspect-ratio
                      (+ start duration (- overlap))
                      stop
                      duration
                      overlap
                      tx
                      (mes:trans start
                                 (if trk (+ start overlap) start)
                                 trk
                                 (mes:image (background-images)
                                            aspect-ratio
                                            start (+ start duration))
                                 (if (and trk tx) tx ())))
    trk))

(define image-loop-fx
  (fn (start stop inputs)
    (image-loop-track 4/3
                      start stop 30.0
                      2.0 dissolve-tx
                      ())))

(define background-fx
  (let ((delta-z -2.0)
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
        ; background images
        (effect-stack
          (effect "Translate" (A)
                  (param "z" delta-z))
          (effect "Scale" (A)
                  (param "x" scale)
                  (param "y" scale))
          image-loop-fx)
        ; foreground
        A))))

(define muvee-global-effect background-fx)


;-----------------------------------------------------------
;   Segment effects
;   - frame with border
;   - captions in front of the input

(define hash
  (let ((ht (mk-hashtable)))
    (fn kv-pair (apply ht kv-pair))))

(define bounded-segment-index
  (fn args
    (if (and args (first args))
      ; (segment-count) is used instead of muvee-last-segment-index
      ; because when used in the context of muvee-transition,
      ; the latter has not been defined yet
      ((limiter 0 (- (segment-count) 1)) (first args))
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
      ; return the x+ and y+ factors (used for defining border)
      (cons x+ y+))))

(define frame-contents-fx
  (fn (x-stretch y-stretch scale)
    (effect-stack
      (effect "Scale" (A)
              (param "x" scale)
              (param "y" scale))
      (effect "Alpha" (A)
              (param "Alpha" 0.999))
      (layers (A)
        (if (!= BORDER 'None)
          ; frame with border
          (effect-stack
            (effect "Scale" (A)
                    (param "x" x-stretch)
                    (param "y" y-stretch))
            (effect "ColorQuad" ()
                    (param "hexColor"
                           (case BORDER
                             ('Black 0xFF000000)
                             (_      0xFFFFFFFF)))))
          ; no border
          (fn args))
        ; user's media
        (effect "Translate" ()
                (input 0 A)
                (param "z" 0.005))
        ; user's captions
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.010))
          muvee-segment-captions)))))

(define frame-content-params
  (fn (segment-index)
    (let ((params (hash segment-index)))
      (if params
        ; retrieve values from hashtable, if previously stored
        params
        ; else generate new set of values and store to hashtable
        (let ((stretch (if (!= BORDER 'None)
                         (xy-stretch-factors segment-index)
                         (cons 1.0 1.0))))
          (hash segment-index (list (first stretch)          ; x-stretch
                                    (rest stretch)           ; y-stretch
                                    (rand 0.70 0.74))))))))  ; scale

(define muvee-segment-effect
  (effect-selector
    (fn args
      (let ((params (frame-content-params (segment-index))))
        (apply frame-contents-fx params)))))


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    (effect "Perspective" (A))
    (effect "Alpha" (A)
            (param "Alpha" 0.999))
    (layers (A)
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.004))
        (effect "ColorQuad" ()
                (param "a" 0.0
                       (at 0.2 1.0)
                       (at 0.8 0.0))))
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.0
                       (linear 0.6 0.0)
                       (linear 0.8 1.0)))
        (effect "Scale" (A)
                (param "x" 1.0
                       (linear 0.6 1.0)
                       (linear 0.8 1.55))
                (param "y" 1.0
                       (linear 0.6 1.0)
                       (linear 0.8 1.55)))
        (effect "Translate" (A)
                (param "z" -0.003))
        (effect "PictureQuad" ()
                (param "OnDemand" 1)
                (param "Path" (resource "background02.jpg"))))
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.0
                       (linear 0.2 0.0)
                       (linear 0.4 1.0)
                       (linear 0.6 1.0)
                       (linear 0.8 0.0)))
        (effect "Scale" (A)
                (param "x" 0.8
                       (linear 0.2 0.8)
                       (linear 0.4 1.3)
                       (linear 0.6 1.3)
                       (linear 0.8 1.9))
                (param "y" 0.8
                       (linear 0.2 0.8)
                       (linear 0.4 1.3)
                       (linear 0.6 1.3)
                       (linear 0.8 1.9)))
        (effect "Translate" (A)
                (param "z" -0.002))
        (effect "PictureQuad" ()
                (param "OnDemand" 1)
                (param "Path" (resource "background03.jpg"))))
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 1.0
                       (linear 0.2 1.0)
                       (linear 0.4 0.0)))
        (effect "Scale" (A)
                (param "x" 1.0
                       (linear 0.2 1.0)
                       (linear 0.4 1.8))
                (param "y" 1.0
                       (linear 0.2 1.0)
                       (linear 0.4 1.8)))
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "PictureQuad" ()
                (param "OnDemand" 1)
                (param "Path" (resource "background01.jpg"))))
      A)))

(title-section
  (background
    (image "transparent.png"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-out)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Impact")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 2.0  dy: 2.0  size: 4.0)))

(credits-section
  (background
    (image "transparent.png"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-in)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Impact")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 2.0  dy: 2.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition dissolve-tx title/credits-tx-dur)

(muvee-body-credits-transition dissolve-tx title/credits-tx-dur)
