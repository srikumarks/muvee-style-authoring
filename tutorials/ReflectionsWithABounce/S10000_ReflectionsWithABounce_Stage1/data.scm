;muSE v2
;
;   S00513_Reflections2
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	REFLECTIVITY	0.5	0.0  1.0)
  (one-of-many		ORNAMENTS	Stars	(Stars  Circles  Squares  All  None)))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration-beats
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration-beats 18.0) 2.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 2.00
                     0.45 0.90
                     1.00 0.40)

(time-warp-tc 0.00 0.25
              0.45 0.75
              1.00 1.00)

(define average-transition-duration-beats
  (+ (* base-duration-beats 6.0) 1.0))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        1.00 1.00)


;-----------------------------------------------------------
;   Global effects

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Alignment" (A) (param "alignment" Alignment_Bottom))
    (effect "Translate" (A) (param "z" -1.0))
    (effect "Perspective" (A) (param "zFar" 50.0))))

(define muvee-global-effect view-fx)


;-----------------------------------------------------------
;   Segment effects
;   - show pictures and videos on a reflective surface with
;     moving polygons
;   - captions in front of the input

(define reflect-fx
  (fn (reflectivity)
    (effect "Reflect" (A)
            (input 0 A)
            (param "floorAlpha" (- 1.0 reflectivity))
            (param "farZ" -1.0))))

(define random-polygon-type
  (shuffled-sequence PolygonType_Circle
                     PolygonType_Square
                     PolygonType_Star))

(define moving-polygons-fx
  (fn (type)
    (if (= type 'None)
      blank
      (layers (A)
        (fn (start stop inputs)
          (apply (effect "MovingPolygons" ()
                         (param "PolygonNum"
                                (let ((v (loudness start)))
                                  (if (= v ()) 5 (trunc (* 20.0 v)))))
                         (param "PolygonType"
                                (case type
                                  ('Circles PolygonType_Circle)
                                  ('Squares PolygonType_Square)
                                  ('Stars   PolygonType_Star)
                                  (_        (random-polygon-type)))))
                 (list start stop inputs)))
        A))))

(define reflection-and-polygons-fx
  (effect-stack
    (reflect-fx REFLECTIVITY)
    (moving-polygons-fx ORNAMENTS)))

(define captions-fx
  (layers (A)
    A
    (effect-stack
      (effect "Translate" (A)
              (param "y" -0.05)
              (param "z" 0.4))
      (effect "Alpha" (A)
              (param "Alpha" 0.999))
      muvee-segment-captions)))

(define muvee-segment-effect
  (effect-stack
    reflection-and-polygons-fx
    captions-fx))


;-----------------------------------------------------------
;   Transitions
;   - fly

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

(define anim-rotate-x
  (fn (rx0 rx1)
    (effect "Rotate" (A)
            (param "ex" 1.0)
            (param "degrees" rx0 (smoove 0.0 rx0 1.0 rx1) 30))))

(define anim-rotate-y
  (fn (ry0 ry1)
    (effect "Rotate" (A)
            (param "ey" 1.0)
            (param "degrees" ry0 (smoove 0.0 ry0 1.0 ry1) 30))))

(define anim-rotate-z
  (fn (rz0 rz1)
    (effect "Rotate" (A)
            (param "ez" 1.0)
            (param "degrees" rz0 (smoove 0.0 rz0 1.0 rz1) 30))))

(define anim-translate-xyz
  (fn ((tx0 ty0 tz0) (tx1 ty1 tz1))
    (effect "Translate" (A)
            (param "x" tx0 (smoove 0.0 tx0 1.0 tx1) 30)
            (param "y" ty0 (smoove 0.0 ty0 1.0 ty1) 30)
            (param "z" tz0 (smoove 0.0 tz0 1.0 tz1) 30))))

(define anim-opacity
  (fn (a0 a1)
    (effect "Alpha" (A)
            (param "Alpha" a0 (smoove 0.0 a0 1.0 a1) 30))))

;;; flying actions ;;;

(define fly1-tx
  (fn (dir)
    (layers (A B)
      (effect-stack
        (anim-translate-xyz (0.0 0.0 0.0) ((* dir 7.0) 5.0 -25.0))
        (anim-rotate-x 0.0 80.0)
        (anim-rotate-y 0.0 (* dir -90.0))
        (anim-rotate-z 0.0 (* dir -60.0))
;        spin
        (with-inputs (list A) (anim-opacity 1.0 0.0)))
      (effect-stack
        (anim-translate-xyz ((* dir -1.0) -1.0 4.0) (0.0 0.0 0.0))
        (anim-rotate-x 60.0 0.0)
        (anim-rotate-y (* dir -60.0) 0.0)
        (anim-rotate-z (* dir 5.0) 0.0)
        (with-inputs (list B) (anim-opacity 1.0 1.0))))))

(define fly2-tx
  (fn (dir)
    (layers (A B)
      (effect-stack
        (anim-translate-xyz (0.0 0.0 0.0) ((* dir -4.0) 1.0 4.0))
        (anim-rotate-x 0.0 20.0)
        (anim-rotate-y 0.0 (* dir -60.0))
        (anim-rotate-z 0.0 (* dir 30.0))
        (with-inputs (list A) (anim-opacity 1.0 1.0)))
      (effect-stack
        (anim-translate-xyz ((* dir 2.5) -1.0 -10.0) (0.0 0.0 0.0))
        (anim-rotate-y (* dir 30.0) 0.0)
        (anim-rotate-z (* dir -10.0) 0.0)
        (with-inputs (list B) (anim-opacity 0.5 1.0))))))

(define fly3-tx
  (fn (dir)
    (layers (A B)
      (effect-stack
        (anim-translate-xyz (0.0 0.0 0.0) ((* dir -3.0) 1.5 2.0))
        (anim-rotate-x 0.0 10.0)
        (anim-rotate-y 0.0 (* dir -20.0))
        (anim-rotate-z 0.0 (* dir -30.0))
        (with-inputs (list A) (anim-opacity 1.0 1.0)))
      (effect-stack
        (anim-translate-xyz ((* dir 10.0) -1.5 -8.0) (0.0 0.0 0.0))
        (anim-rotate-x 20.0 0.0)
        (anim-rotate-y (* dir 40.0) 0.0)
        (anim-rotate-z (* dir 30.0) 0.0)
        (with-inputs (list B) (anim-opacity 1.0 1.0))))))

(define fly4-tx
  (fn (dir)
    (layers (A B)
      (effect-stack
        (anim-translate-xyz (0.0 0.0 0.0) ((* dir -1.5) -1.0 3.0))
        (anim-rotate-x 0.0 30.0)
        (anim-rotate-y 0.0 (* dir -50.0))
        (with-inputs (list A) (anim-opacity 1.0 1.0)))
      (effect-stack
        (anim-translate-xyz ((* dir 1.0) 0.0 -8.0) (0.0 0.0 0.0))
        (anim-rotate-y (* dir 60.0) 0.0)
        (with-inputs (list B) (anim-opacity 0.5 1.0))))))

;;; transition selection ;;;

(define random-direction
  (random-sequence -1.0 1.0))

(define fly-tx
  (effect-selector
    (apply looping-sequence ;shuffled-sequence
           (map (fn (tx)
                  (fn args
                    (apply (tx (random-direction)) args)))
                (list fly1-tx fly2-tx fly3-tx fly4-tx)))))

(define muvee-transition fly-tx)


;-----------------------------------------------------------
;   Title and credits

(define is4:3?
  (< (fabs (- render-aspect-ratio 4/3)) 0.1))

(define BACKGROUND_IMAGE
  (format (if is4:3? "4-3" "16-9") "_panel.png"))

(define FOREGROUND_FX
  (effect-stack view-fx reflection-and-polygons-fx))

(title-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.05 0.05) (0.95 0.95))))

(credits-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.05 0.05) (0.95 0.95))))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  (beat->sec average-transition-duration-beats (tempo 0)))

(muvee-title-body-transition (fly4-tx 1.0) title/credits-tx-dur)

(muvee-body-credits-transition (fly1-tx -1.0) title/credits-tx-dur)
