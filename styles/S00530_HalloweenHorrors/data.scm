;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00530_HalloweenHorrors
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (one-of-few		FLIP_STYLE	Curl	(Curl  Roll))
  (continuous-slider	FLIP_VARIATION	0.25	0.0  1.0))


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
  (let ((path (fn (file) (format "overlays/" file)))
        (files (list-files (resource (path "*.png"))))
        (seq (apply shuffled-sequence (map path files))))
    (if n
      (path (format (first n) ".png"))
      (seq))))

(define overlays-layout-seq
  (looping-sequence
    '(list (list (overlay "01") top    right  0.0  0.38 ()   0.0))
    '(list (list (overlay "04") top    left   0.0  0.38 ()  22.0))
    '(list (list (overlay "10") top    right  0.0  0.32 ()   0.0)
           (list (overlay "11") bottom left   0.0  0.38 ()   0.0))
    '(list (list (overlay "02") top    left   0.0  0.32 ()   0.0))
    '(list (list (overlay "16") top    left   0.0  0.32 ()   0.0)
           (list (overlay "15") bottom right  0.0  0.38 ()   0.0))
    '(list (list (overlay "07") 0.9    left  -0.12 0.38 ()   0.0))
    '(list (list (overlay "05") top    right  0.0  0.32 ()   0.0)
           (list (overlay "06") bottom left  -0.07 0.38 ()   0.0))
    '(list (list (overlay "08") top    left  -0.12 0.38 ()  10.0)
           (list (overlay "09") top    right  0.0  0.38 ()  10.0))
    '(list (list (overlay "12") top    left  -0.05 0.32 ()   0.0))
    '(list (list (overlay "13") top    left   0.0  0.32 ()   0.0)
           (list (overlay "14") bottom right  0.0  0.38 () -20.0))))

(define layout-seq
  (fn args
    (if (< (rand 1.0) 0.5)  ; 50% chance of overlays
      (eval (overlays-layout-seq))
      ())))


;-----------------------------------------------------------
;   Segment effects
;   - frame video and pictures with a translucent border
;     and drop shadow against a themed background,
;     decorated with ornaments along the edges
;   - captions within the input frame

(define render-aspect-ratio-str
  (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) "4-3" "16-9"))

(define theme-path
  (fn (file)
    (format "backgrounds/" file)))

(define backpage
  (theme-path (format render-aspect-ratio-str "_backpage.jpg")))

(define background-seq
  (let ((spec (format render-aspect-ratio-str "_0*.jpg"))
        (files (list-files (resource (theme-path spec)))))
    (apply looping-sequence
           (map theme-path files))))

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
  (fn (background backpage overlays x-offset y-offset rotate scale border)
    (layers (A)
      ; backpage
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.005))
        (effect "PictureQuad" ()
                (param "Quality" Quality_Higher)
                (param "Path" (resource backpage))))
      ; background
      (effect-stack
        (effect "Scale" (A)
                (param "x" 1.01)
                (param "y" 1.01))
        (effect "PictureQuad" ()
                (param "Quality" Quality_Higher)
                (param "Path" (resource background))))
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
    (fn args (page-contents-fx (background-seq)   ; background
                               backpage           ; back of page
                               (layout-seq)       ; overlay layout
                               (rand -0.06 0.06)  ; x-offset
                               (rand -0.04 0.04)  ; y-offset
                               (rand -3.00 3.00)  ; rotate
                               (rand 0.70 0.74)   ; scale
                               0.06))))           ; border

(define muvee-segment-effect page)


;-----------------------------------------------------------
;   Transitions
;   - page flip

(define page-flip-tx
  (let ((delta-z -0.025)  ; increasing this distance causes roll problems
        (fovy 45.0)  ; assumes 45" fovy
        (tangent (tan (deg->rad (* fovy 0.5))))
        (scale (- 1.0 (* tangent delta-z))))
    (fn (angle mode)
      (layers (A B)
        ; put next page behind, but scale up to fill output frame
        (effect-stack
          (effect "Alpha" (A)
                  (param "Alpha" 0.999))
          (effect "Scale" (A)
                  (param "x" scale)
                  (param "y" scale))
          (effect "Translate" ()
                  (input 0 B)
                  (param "z" delta-z)))
        ; flip current page
        (effect "PageCurl" ()
                (input 0 A)
                (param "Angle" angle)
                (param "Mode" mode))))))

(define turn-to-next-page
  (let ((mode (if (= FLIP_STYLE 'Curl) Mode_Curl Mode_Roll)))
    (fn args
      (apply (page-flip-tx (+ 100.0 (* (rand -180.0 180.0)
                                       FLIP_VARIATION
                                       FLIP_VARIATION))
                           mode)
             args))))

(define muvee-transition turn-to-next-page)


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    (effect "Translate" (A)
            (param "z" -0.01))
    (effect "Scale" (A)
            (param "x" 1.01)
            (param "y" 1.01))
    (effect "Perspective" (A))))

(title-section
  (audio-clip "halloween.mvx" gaindb: 3.0)
  (background
    (video "halloween.wmv"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 150 35 3)
    (font "-19,0,0,0,800,0,0,0,0,3,2,1,34,Palatino Linotype")
    (layout (0.10 0.10) (0.90 0.86))
    (soft-shadow  dx: 1.0  dy: 1.0  size: 4.0)))

(credits-section
  (audio-clip "halloween.mvx" gaindb: 3.0)
  (background
    (video "halloween.wmv"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 168 35 3)
    (font "-19,0,0,0,800,0,0,0,0,3,2,1,34,Palatino Linotype")
    (layout (0.10 0.10) (0.90 0.86))
    (soft-shadow  dx: 1.0  dy: 1.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition turn-to-next-page title/credits-tx-dur)

(muvee-body-credits-transition turn-to-next-page title/credits-tx-dur)
