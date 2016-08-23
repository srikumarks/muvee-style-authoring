;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00527_MixMatch1
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
  (one-of-few		DIRECTION	Both		(Both  Horiz  Vert))
  (one-of-few		OVERLAYS	Overlays2	(Overlays1  Overlays2)))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED 0.5)


;-----------------------------------------------------------
;   Global effects

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))

(define muvee-global-effect view-fx)


;-----------------------------------------------------------
;   Overlays
;   - layout

(define (overlay . n)
  (let ((path (fn (file) (format OVERLAYS "/" file)))
        (files (list-files (resource (path "*.png"))))
        (seq (apply shuffled-sequence (map path files))))
    (if n
      (path (format (first n) ".png"))
      (seq))))

(define overlays1-layout-seq
  (shuffled-sequence
    '(list (list (overlay "10") top    center  0.08 0.6 () (rand  82.0  98.0))
           (list (overlay "09") bottom center  0.10 0.6 () (rand -98.0 -82.0)))
    '(list (list (overlay "05") center left    0.05 0.5 () (rand  -8.0   8.0))
           (list (overlay "07") center right   0.05 0.5 () (rand  -8.0   8.0)))
    '(list (list (overlay "08") top    right  -0.10 0.5 () (rand  30.0  60.0))
           (list (overlay "05") bottom left   -0.10 0.5 () (rand  30.0  60.0)))
    '(list (list (overlay "10") top    left   -0.10 0.5 () (rand -60.0 -30.0))
           (list (overlay "09") bottom right  -0.12 0.5 () (rand -60.0 -30.0)))
    '(list (list (overlay "01") top    left    0.05 0.5 () (rand -45.0 -30.0))
           (list (overlay "03") top    right   0.00 0.4 () (rand -60.0  60.0))
           (list (overlay "10") bottom center  0.05 0.7 () (rand -98.0 -82.0)))
    '(list (list (overlay "03") top    left    0.00 0.4 () (rand  60.0 120.0))
           (list (overlay "05") top    right   0.08 0.4 () (rand  70.0 100.0))
           (list (overlay "07") bottom left    0.00 0.5 () (rand  60.0  95.0))
           (list (overlay "02") bottom right   0.00 0.4 () (rand   0.0  70.0)))
    '(list (list (overlay "04") top    center  0.05 0.5 () (rand  82.0  98.0))
           (list (overlay "08") bottom center  0.05 0.5 () (rand  82.0  98.0))
           (list (overlay "06") center left    0.05 0.4 () (rand  -8.0   8.0))
           (list (overlay "09") center right   0.05 0.4 () (rand  -8.0   8.0)))))

(define overlays2-layout-seq
  (shuffled-sequence
    '(list (list (overlay) top    center -0.05 0.25 () (rand -30.0 30.0)))
    '(list (list (overlay) top    left   -0.05 0.25 () (rand -30.0 30.0))
           (list (overlay) top    right  -0.05 0.25 () (rand -30.0 30.0)))
    '(list (list (overlay) top    left   -0.05 0.25 () (rand -30.0 30.0))
           (list (overlay) top    right  -0.05 0.25 () (rand -30.0 30.0))
           (list (overlay) bottom left   -0.05 0.25 () (rand -30.0 30.0))
           (list (overlay) bottom right  -0.05 0.25 () (rand -30.0 30.0)))))

(define layout-seq
  (fn args
    (if (< (rand 1.0) 0.8)  ; 80% chance of overlays
      (eval (if (= OVERLAYS 'Overlays1)
              (overlays1-layout-seq)
              (overlays2-layout-seq)))
      ())))


;-----------------------------------------------------------
;   Segment effects
;   - frame video and pictures with an opaque border
;     and drop shadow against a themed background,
;     decorated with ornaments along the edges
;   - captions within the input frame

(define render-aspect-ratio-str
  (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) "4-3" "16-9"))

(define background-image
  (format render-aspect-ratio-str "_background.jpg"))

(define border+shadow
  (format render-aspect-ratio-str "_border.png"))

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

(define frame-overlay-fx
  (fn (screen-aspect-ratio stretch-x stretch-y)
    (fn (image pos-vert pos-horiz offset scale flip degrees)
      (let ((anchor-x (case pos-horiz
                        ('left   -1.0)
                        ('center  0.0)
                        ('right   1.0)
                        (_        pos-horiz)))
            (anchor-y (case pos-vert
                        ('bottom -1.0)
                        ('center  0.0)
                        ('top     1.0)
                        (_        pos-vert)))
            ((flip-x . flip-y) (case flip
                                 ('flip-x  (cons -1.0  1.0))
                                 ('flip-y  (cons  1.0 -1.0))
                                 ('flip-xy (cons -1.0 -1.0))
                                 (_        (cons  1.0  1.0)))))
        (effect-stack
          (effect "Translate" (A)
                  (param "x" (* anchor-x stretch-x render-aspect-ratio
                                (+ 1.0 (/ offset screen-aspect-ratio))))
                  (param "y" (* anchor-y stretch-y
                                (+ 1.0 offset)))
                  ; this is stacked higher than captions,
                  ; but given random z-offsets to minimize
                  ; z-fighting with one another, especially
                  ; when they happen to be very close together
                  (param "z" (rand 0.018 0.022)))
          (effect "Scale" (A)
                  (param "x" (* flip-x scale))
                  (param "y" (* flip-y scale)))
          (effect "Rotate" (A)
                  (param "ez" 1.0)
                  (param "degrees" degrees))
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Lower)
                  (param "Path" (resource image))))))))

(define frame-contents-fx
  (fn (overlays border)
    (let ((screen-aspect-ratio (crop-aspect-ratio))
          (factor (/ screen-aspect-ratio render-aspect-ratio))
          ((x . y) (xy-stretch-fit-to-source factor))
          ; make constant-width border regardless of:
          ; - content's edge (left, right, top, bottom)
          ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
          ; - render aspect ratio (4:3 or 16:9)
          (b+ (if (> factor 1.0) (* border factor) border))
          (x+ (* x (+ 1.0 (/ b+ screen-aspect-ratio))))
          (y+ (* y (+ 1.0 b+)))
          ; set frame overlay helper function arguments
          (fo (frame-overlay-fx screen-aspect-ratio x y)))
      (layers ()
        ; border and drop shadow
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.005))
          ; artwork is designed such that the border occupies
          ; exactly 90% of the frame size; additional scaling
          ; of 10/9 is needed to fit it to the content's area
          (effect "Scale" (A)
                  (param "x" (* 10/9 x+))
                  (param "y" (* 10/9 y+)))
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Normal)
                  (param "Path" (resource border+shadow))))
        ; user's media
        (effect "Translate" ()
                (input 0 A)
                (param "z" 0.010))
        ; user's captions
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.015))
          muvee-segment-captions)
        ; frame overlays
        (eval (apply layers
                     (append! (list '())
                              (map (fn (o) (apply fo o)) overlays))))))))

(define page-contents-fx
  (fn (overlays x-offset y-offset rotate scale border)
    (layers (A)
      ; background
      (effect-stack
        (effect "Scale" (A)
                (param "x" 1.0012)
                (param "y" 1.002))
        (effect "SeamlessBackground" ()
                ; load-on-demand prevents crash by having separate
                ; resids from the copies used in title and credits
                (param "OnDemand" 1)
                (param "Quality" Quality_Higher)
                (param "Path" (resource background-image))))
      ; foreground
      (effect-stack
        ; positioning
        (effect "Translate" (A)
                (param "x" x-offset)
                (param "y" y-offset))
        (effect "Rotate" (A)
                (param "ex" 0.0)
                (param "ey" 0.0)
                (param "ez" 1.0)
                (param "degrees" rotate))
        (effect "Scale" (A)
                (param "x" scale)
                (param "y" scale))
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        ; frame contents
        (frame-contents-fx overlays border)))))

(define page
  (effect-selector
    (fn args (page-contents-fx (layout-seq)       ; overlay layout
                               (rand -0.06 0.06)  ; x-offset
                               (rand -0.04 0.04)  ; y-offset
                               (rand -3.00 3.00)  ; rotate
                               (rand  0.70 0.76)  ; scale
                               0.06))))           ; border

(define muvee-segment-effect page)


;-----------------------------------------------------------
;   Transitions
;   - push

(define fast-accel-slow-decel-fn
  (fn (t)
    (cond
      ((<= t 0.0) 0.0)
      ((>= t 1.0) 1.0)
      ((< t 0.09) (* 26.75 t t))  ; fast accel
      (_ (- 1.003346 (exp (+ (* -6.0 t) 0.3)))))))  ; slow decel

(define smoove
  ; sets up parameters for the animation curve so as to get
  ; "smooth-move" between a and b from progress p0 to p1
  (fn (p0 a p1 b)
    (let ((tc (linear-tc 0.0 0.0 p0 0.0 p1 1.0 1.0 1.0)))
      (fn (p)
        (+ (* (- b a) (fast-accel-slow-decel-fn (tc p))) a)))))

(define push-tx
  (fn (dir)
    ; 0=up, 1=down, 2=left, 3=right
    (let ((dir%4 (% dir 4))
          (units (if (or (= dir%4 1) (= dir%4 2)) -2.0 2.0))
          ((axis . vec) (if (> dir%4 1)
                          (cons "x" (* units render-aspect-ratio))
                          (cons "y" units)))
          (~vec (- vec)))
      (layers (A B)
        (effect "Translate" ()
                (input 0 A)
                (param "z" -0.001)
                (param axis 0.0 (smoove 0.0 0.0 1.0 vec)))
        (effect "Translate" ()
                (input 0 B)
                (param axis ~vec (smoove 0.0 ~vec 1.0 0.0)))))))

(define direction
  (let ((dir (case DIRECTION
               ('Vert  (list 0 1 0 1))
               ('Horiz (list 2 3 2 3))
               (_      (list 0 1 2 3)))))
    (apply shuffled-sequence dir)))

(define push-to-next-page
  (effect-selector
    (fn args (push-tx (direction)))))

(define muvee-transition push-to-next-page)


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    (effect "Scale" (A)
            (param "x" 1.01)
            (param "y" 1.01))
    (effect "Alpha" (A)
            (param "Alpha" 0.999))
    (effect "Perspective" (A))))

(title-section
  (background
    (image background-image))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'left 'bottom)
    (color 0 0 0)
    (font "-24,0,0,0,800,0,0,0,0,3,2,1,34,Palatino Linotype")
    (layout (0.10 0.10) (0.90 0.90))))

(credits-section
  (background
    (image background-image))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'left 'bottom)
    (color 0 0 0)
    (font "-24,0,0,0,800,0,0,0,0,3,2,1,34,Palatino Linotype")
    (layout (0.10 0.10) (0.90 0.90))))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(define push-left/right/up
  ; forbid pushing down in title and credits
  ; so that rolling credits do not interfere
  ; with user's clip in the first and last segment
  (case DIRECTION
    ('Horiz push-to-next-page)
    ('Vert  (push-tx 0))
    (_      (let ((dir (shuffled-sequence 0 2 3)))
              (effect-selector
                (fn args (push-tx (dir))))))))

(muvee-title-body-transition push-left/right/up title/credits-tx-dur)

(muvee-body-credits-transition push-left/right/up title/credits-tx-dur)
