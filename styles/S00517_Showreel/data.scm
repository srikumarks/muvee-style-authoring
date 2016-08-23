;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00517_Showreel
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
  (one-of-few		DIRECTION	Horiz		(Horiz  Vert))
  (one-of-few		FILM_TYPE	Standard	(Standard  Grunge)))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration-beats
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration-beats 21.0) 3.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 2.00
                     1.00 0.40)

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
;   - background

(define scale-fx
  (fn (factor)
    (effect "Scale" (A)
            (param "x" factor)
            (param "y" factor))))

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
        ; background
        (effect-stack
          (effect "Translate" (A)
                  (param "z" delta-z))
          (scale-fx scale)
          (effect "Fit" (A))  ; aspect ratio has to be 1:1
          (effect "PictureQuad" ()
                  (param "Quality" Quality_Normal)
                  (param "Path" (resource "backbase.jpg"))))
        ; foreground
        A))))

(define muvee-global-effect background-fx)


;-----------------------------------------------------------
;   Segment effects
;   - film overlay
;   - captions

(define is4:3?
  (< (fabs (- render-aspect-ratio 4/3)) 0.1))

(define film-sandwich-fx
  (let ((overlay-scale-x (+ 1.0 1/240))
        (overlay-scale-y (+ 1.0 (/ 1/240 render-aspect-ratio)))
        (content-scale-xy 0.808))
    (fn (file filmbase?)
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (effect "Scale" (A)
                (param "x" overlay-scale-x)
                (param "y" overlay-scale-y))
        (layers (A)
          ; film underlay (behind the black surface)
          ; is unnecessary here because:
          ; - opacity increases after layering with the top-most
          ; film overlay, hence resulting to darker shadows and
          ; more opaque translucent regions (escpecially with
          ; the "Standard" film set)
          ; - our film sprockets are specially designed to be
          ; symmetrical about the axis of the twist
          
          ; user's media (behind the black surface)
          (effect-stack
            (effect "Translate" (A)
                    (param "z" -0.001))
            (with-inputs (list A) (scale-fx content-scale-xy)))
          ; black surface
          ; (unnecessarily only during title and credits because
          ; it obstructs user-selected background color)
          (if filmbase?
            (effect-stack
              (scale-fx content-scale-xy)
              (effect "Fit" (A))  ; filmbase aspect ratio must be 1:1
              ; ColorQuad can't twist, so use PictureQuad instead!
              (effect "PictureQuad" ()
                      (param "Quality" Quality_Lowest)
                      (param "Path" (resource "filmbase.jpg"))))
            (fn (start stop ())))
          ; user's media
          (effect-stack
            (effect "Translate" (A)
                    (param "z" 0.001))
            (with-inputs (list A) (scale-fx content-scale-xy)))
          ; film overlay
          (effect-stack
            (effect "Translate" (A)
                    (param "z" 0.002))
            (effect "PictureQuad" ()
                    (param "Quality" Quality_Higher)
                    (param "Path" (resource file)))))))))

(define film-path
  (fn (file)
    (format FILM_TYPE "/" file)))

(define film-stock-seq
  (let ((filespec (format (if is4:3? "4-3" "16-9") "_" DIRECTION "_*.png"))
        (files (list-files (resource (film-path filespec)))))
    (apply looping-sequence
           (map film-path files))))

(define film-fx-sel
  (fn args
    (film-sandwich-fx (film-stock-seq) T)))

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
  (effect-stack
    (custom-effect-selector film-fx-sel)
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - dissolve
;   - push
;   - push with twist

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

;;; push ;;;

(define push-tx
  (let (((axis . vec) (if (= DIRECTION 'Vert)
                        (cons "y" 2.0)
                        (cons "x" (* render-aspect-ratio -2.0))))
        (~vec (- vec)))
    (layers (A B)
      (effect "Translate" ()
              (input 0 A)
              (param "z" 0.001)
              (param axis 0.0
                     (bezier 1.0 vec 0.0 vec)))
      (effect "Translate" ()
              (input 0 B)
              (param axis ~vec
                     (bezier 1.0 0.0 ~vec 0.0))))))

;;; push with twist ;;;

(define push+twist-tx
  (let ((vert? (= DIRECTION 'Vert))
        ((axis . vec) (if vert?
                        (cons "y" 2.0)
                        (cons "x" (* render-aspect-ratio -2.0))))
        (~vec (- vec))
        (thepush (fn (ip v0 v1)
                   (effect "Translate" ()
                           (input 0 ip)
                           (param axis v0 (bezier 1.0 v1 v0 v1)))))
        (thetwist (fn (num)
                    (effect "Twist" (A)
                            (param "input" num)
                            (param "axis" (if vert? Axis_Y Axis_X))
                            (param "constant" (- (fabs vec))))))
        ; Specify the progress where the twist effect will end,
        ; but the push effect will still end at progress 1.0.
        ; This prevents the revealing of film's edge which
        ; suggests a break in the continuity.
        (twist-stop-prog (if vert? 0.8 0.9)))
    (layers (A B)
      ; input-A
      (fn (start stop inputs)
        (let ((push-a (apply (thepush A 0.0 vec)
                             (list start stop inputs)))
              (twist-stop (apply (linear-tc 0.0 start 1.0 stop)
                                 (list twist-stop-prog)))
              (twist-a (apply (thetwist 0)
                              (list start twist-stop (list push-a)))))
          twist-a))
      ; input-B
      (fn (start stop inputs)
        (let ((push-b (apply (thepush B ~vec 0.0)
                             (list start stop inputs)))
              (twist-stop (apply (linear-tc 0.0 start 1.0 stop)
                                 (list twist-stop-prog)))
              (twist-b (apply (thetwist 1)
                              (list start twist-stop (list push-b)))))
          twist-b)))))

;;; transition selection ;;;

(define tx-seq
  (looping-sequence push-tx
                    push-tx
                    push+twist-tx
                    push-tx
                    push-tx
                    push-tx
                    push-tx
                    push+twist-tx
                    push-tx))

(define tx-sel
  (let ((prev-start (list 0)))
    (fn (start stop inputs)
      (if (change-background? (segment-index) start (first prev-start))
        (do
          (setf! prev-start start)
          (tx-seq))
        dissolve-tx))))

(define muvee-transition
  (effect-selector tx-sel))


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    background-fx
    (film-sandwich-fx (film-stock-seq) ())))

(title-section
  (audio-clip "sfx-title.mvx" gaindb: -3.0)
  (background
    (video "background-title.wmv"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)
	(text-display-interval 0.4523 1.0)
    (custom-parameters
      (param "FadeText" 0.0
             (at (effect-time 4.071) 1.0)
             (at (effect-time 7.5) 1.0)
             (linear (effect-time 9.0) 0.0)))))

(credits-section
  (audio-clip "sfx-credits.mvx" gaindb: -3.0)
  (background
    (image "background-credits.jpg"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  (beat->sec average-transition-duration-beats (tempo 0)))

(muvee-title-body-transition push-tx title/credits-tx-dur)

(muvee-body-credits-transition push-tx title/credits-tx-dur)
