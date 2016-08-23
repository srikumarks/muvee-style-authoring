;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00511_Journal2
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (one-of-many		THEME		Lifestory	(Lifestory  Grunge  Floral  Damask  Abstract))
  (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
  (one-of-few		FLIP_STYLE	Curl		(Curl  Roll))
  (continuous-slider	FLIP_VARIATION	0.25		0.0  1.0))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration-beats
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration-beats 21.0) 3.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 1.50
                     1.00 0.50)

(time-warp-tc 0.00 0.50
              0.45 1.00
              1.00 1.00)

(define average-transition-duration-beats
  (+ (* base-duration-beats 2.0) 2.0))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.20
                        1.00 0.60)


;-----------------------------------------------------------
;   Global effects

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))

(define muvee-global-effect view-fx)


;-----------------------------------------------------------
;   Segment effects
;   - frame video and pictures with a translucent border
;     and drop shadow against a themed background
;   - captions within the input frame

(define (float= x y err) 
  (and (> x (- y err)) (< x (+ y err))))

(define theme-path
  (fn (file)
    (format THEME "/" file)))

(define backpage
  (if (= THEME 'Damask)
    ()
    (theme-path "backpage.jpg")))

(define background-seq
  (let ((files (list-files (resource (theme-path "0*.jpg")))))
    (apply looping-sequence
           (map theme-path files))))

(define border+shadow
  (format (if (float= render-aspect-ratio 4/3 0.001) "4-3" "16-9")
          "_border.png"))

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

(define page-contents-fx
  (fn (bkgnd bkpg (x y) (r s) b)
    (layers (A)
      (if bkpg
        ; backpage needed
        (effect-stack
          (effect "Translate" (A)
                  (param "z" -0.005))
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Higher)
                  (param "Path" (resource bkpg))))
        ; no backpage needed
        (fn args))
      ; background
      (effect "PictureQuad" ()
              (param "OnDemand" 1)
              (param "Quality" Quality_Higher)
              (param "Path" (resource bkgnd)))
      ; foreground
      (effect-stack
        ; positioning
        (effect "Translate" (A)
                (param "x" x)
                (param "y" y))
        (effect "Rotate" (A)
                (param "ex" 0.0)
                (param "ey" 0.0)
                (param "ez" 1.0)
                (param "degrees" r))
        (effect "Scale" (A)
                (param "x" s)
                (param "y" s))
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        ; content
        (layers ()
          ; border and drop shadow
          (let ((screen-aspect-ratio (crop-aspect-ratio))
                (factor (/ screen-aspect-ratio render-aspect-ratio))
                ((x . y) (xy-stretch-fit-to-source factor))
                ; make constant-width border regardless of:
                ; - content's edge (left, right, top, bottom)
                ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
                ; - render aspect ratio (4:3 or 16:9)
                (b+ (if (> factor 1.0) (* b factor) b))
                (x+ (* x (+ 1.0 (/ b+ screen-aspect-ratio))))
                (y+ (* y (+ 1.0 b+))))
            (effect-stack
              (effect "Translate" (A)
                      (param "z" 0.005))
              (effect "Alpha" (A)
                      (param "Alpha" 0.5))
              ; artwork is designed such that the border occupies
              ; exactly 90% of the frame size; additional scaling
              ; of 10/9 is needed to fit it to the content's area
              (effect "Scale" (A)
                      (param "x" (* 10/9 x+))
                      (param "y" (* 10/9 y+)))
              (effect "PictureQuad" ()
                      (param "Quality" Quality_Normal)
                      (param "Path" (resource border+shadow)))))
          ; user's media
          (effect "Translate" ()
                  (input 0 A)
                  (param "z" 0.010))
          ; user's captions
          (effect-stack
            (effect "Translate" (A)
                    (param "z" 0.015))
            muvee-segment-captions))))))

(define page
  (fn args
    (let ((angle    (rand -3.00 3.00))
          (scale    (rand  0.70 0.76))
          (x-offset (rand -0.06 0.06))
          (y-offset (rand -0.04 0.04)))
      (page-contents-fx (background-seq)
                        backpage
                        (x-offset y-offset)
                        (angle scale)
                        0.06))))

;;; segment selection ;;;

(define change-background?
  ; don't change background between two successive video segments
  ; with the same aspect ratios, and when the current effect spans
  ; significantly less than the average segment duration
  (fn (segment-num start-time prev-start-time)
    (let ((avg-dur (beat->sec average-segment-duration-beats (tempo start-time))))
      (or (< segment-num 0)
          (not (and (source-is-video? segment-num)
                    (source-is-video? (+ segment-num 1))))
          (!= (source-aspect-ratio segment-num)
              (source-aspect-ratio (+ segment-num 1)))
          (> (- start-time prev-start-time) (* 0.9 avg-dur))))))

(define custom-effect-selector
  (fn (next-effect)
    (let ((prev-effect (list ()))
          (prev-start  (list ())))
      (fn (start stop inputs)
        (when (change-background? (- (segment-index) 1) start (first prev-start))
          (do
            (setf! prev-start start)
            (setf! prev-effect (next-effect start stop inputs))))
        ((first prev-effect) start stop inputs)))))

(define muvee-segment-effect
  (custom-effect-selector page))


;-----------------------------------------------------------
;   Transitions
;   - dissolve
;   - page flip

;;; dissolve ;;;

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

;;; page flip ;;;

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

;;; transition selection ;;;

(define tx-sel
  (let ((prev-start (list 0)))
    (fn (start stop inputs)
      (if (change-background? (segment-index) start (first prev-start))
        (do
          (setf! prev-start start)
          turn-to-next-page)
        dissolve-tx))))

(define muvee-transition
  (effect-selector tx-sel))


;-----------------------------------------------------------
;   Title and credits

(define BACKGROUND_IMAGE
  (theme-path "background.jpg"))

(define FOREGROUND_FX
  (effect-stack
    view-fx
    (if backpage
      ; backpage needed
      (layers (A)
        (effect-stack
          (effect "Translate" (A)
                  (param "z" -0.003))
          ; unlike in the muvee body, title image background
          ; is cropped to render aspect ratio, so we rescale
          ; this 16:9 artwork to fit the current aspect ratio
          (effect "Scale" (A)
                  (param "x" (* render-aspect-ratio 9/16)))
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Higher)
                  (param "Path" (resource backpage))))
        A)
      ; no backpage needed
      blank)))

(define TEXT_COLOR
  (case THEME
    ('Abstract 0xFF446D84)
    ('Damask 0xFFAB752D)
    ('Floral 0xFFD8D8D4)
    ('Grunge 0xFF7A6015)
    ('Lifestory 0xFF854B09)))

(define TEXT_FONT
  (case THEME
    ('Abstract "-21,0,0,0,400,0,0,0,0,3,2,1,34,Microsoft Sans Serif")
    ('Damask "-23,0,0,0,400,0,0,0,0,3,2,1,34,Palatino Linotype")
    ('Floral "-24,0,0,0,400,1,0,0,0,3,2,1,34,Times New Roman")
    ('Grunge "-20,0,0,0,700,0,0,0,0,3,2,1,34,Impact")
    ('Lifestory "-21,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")))

(define TEXT_LAYOUT_Y
  (case THEME  
    ('Abstract (cons 0.30 0.90))
    (_ (cons 0.10 0.90))))

(title-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color TEXT_COLOR)
    (font TEXT_FONT)
    (layout (0.10 (first TEXT_LAYOUT_Y))
            (0.90 (rest TEXT_LAYOUT_Y)))))

(credits-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color TEXT_COLOR)
    (font TEXT_FONT)
    (layout (0.10 (first TEXT_LAYOUT_Y))
            (0.90 (rest TEXT_LAYOUT_Y)))))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  (beat->sec average-transition-duration-beats (tempo 0)))

(muvee-title-body-transition turn-to-next-page title/credits-tx-dur)

(muvee-body-credits-transition turn-to-next-page title/credits-tx-dur)
