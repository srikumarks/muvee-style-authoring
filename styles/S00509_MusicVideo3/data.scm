;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00509_MusicVideo3
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (continuous-slider	ENERGY_LEVEL	0.5	0.0  1.0))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed
;   - transfer curves subdomain mapping

(let ((tc-mid (+ (* AVERAGE_SPEED 0.5) 0.25))
      (tc-dev (* MUSIC_RESPONSE 0.25)))
  (map-tc-subdomain (- tc-mid tc-dev) (+ tc-mid tc-dev)))

(segment-durations 4.0)

(segment-duration-tc 0.00 8.00
                     0.25 4.00
                     0.50 1.00
                     0.75 0.50
                     1.00 0.25)

(time-warp-tc 0.00 0.10
              0.35 0.50
              0.65 1.00
              1.00 1.00)

; Notes on transition duration:
;
; - Some of our transitions are actually specified within
; the segment itself (a.k.a. pseudo-transitional animated
; segment effects, i.e. "slide-in/out", "pre/post-crash",
; "ghosts-in/out", "splits-in/out"), and their durations
; are set in segment-effect-selector function below
;
; - This only contols the durations of Dissolves and
; Rotates, but we need it to be dependant on Energy Level
; setting (min -> 1.5 beats, max -> 0.5 beats), so that
; these transitions have minimum interference with the
; opacity-varying pseudo-transitional effects

(preferred-transition-duration (- 1.5 ENERGY_LEVEL))

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        0.50 1.00
                        0.75 0.50
                        1.00 0.25)


;-----------------------------------------------------------
;   Helper effect macros

(define set-param
  (fn (name arg)
    (if (cons? arg)
      (append! (list 'param name) arg)
      (list 'param name arg))))

(define fx:image
  (fn (file)
    (effect "PictureQuad" ()
            (param "Path" (resource file)))))

(define fx:opacity
  (fn '($a)
    (apply effect
           (list "Alpha" '(A)
                 (set-param "Alpha" $a)))))

(define fx:scale-xyz
  (fn '($x $y $z)
    (apply effect
           (list "Scale" '(A)
            (set-param "x" $x)
            (set-param "y" $y)
            (set-param "z" $z)))))

(define fx:scale-xy
  (fn '($x $y)
    (apply fx:scale-xyz (list $x $y 1.0))))

(define fx:scale-x
  (fn '($x)
    (apply fx:scale-xyz (list $x 1.0 1.0))))

(define fx:scale-y
  (fn '($y)
    (apply fx:scale-xyz (list 1.0 $y 1.0))))

(define fx:scale-z
  (fn '($z)
    (apply fx:scale-xyz (list 1.0 1.0 $z))))

(define fx:scale
  (fn '($s)
    (apply fx:scale-xyz (list $s $s $s))))

(define fx:translate-xyz
  (fn '($x $y $z)
    (apply effect
           (list "Translate" '(A)
                 (set-param "x" $x)
                 (set-param "y" $y)
                 (set-param "z" $z)))))

(define fx:translate-xy
  (fn '($x $y)
    (apply fx:translate-xyz (list $x $y 0.0))))

(define fx:translate-x
  (fn '($x)
    (apply fx:translate-xyz (list $x 0.0 0.0))))

(define fx:translate-y
  (fn '($y)
    (apply fx:translate-xyz (list 0.0 $y 0.0))))

(define fx:translate-z
  (fn '($z)
    (apply fx:translate-xyz (list 0.0 0.0 $z))))

(define fx:rotate-xyz-deg
  (fn '($x $y $z $deg)
    (apply effect
           (list "Rotate" '(A)
                 (set-param "ex" $x)
                 (set-param "ey" $y)
                 (set-param "ez" $z)
                 (set-param "degrees" $deg)))))

(define fx:rotate-x
  (fn '($deg)
    (apply fx:rotate-xyz-deg (list 1.0 0.0 0.0 $deg))))

(define fx:rotate-y
  (fn '($deg)
    (apply fx:rotate-xyz-deg (list 0.0 1.0 0.0 $deg))))

(define fx:rotate-z
  (fn '($deg)
    (apply fx:rotate-xyz-deg (list 0.0 0.0 1.0 $deg))))

(define fx:mask
  (fn (x0 y0 x1 y1)
    (effect "TextureSubset" (A)
            (param "x0" x0)
            (param "y0" y0)
            (param "x1" x1)
            (param "y1" y1))))


;-----------------------------------------------------------
;   Helper functions

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

;;; inputs moving to/from edges ;;;

(define random-coordinates-from-the-edge
  (fn (edge)
    (case edge
      ; coordinates deliberately set to avoid corners
      ('left   (cons (* render-aspect-ratio -2.0) (rand -1.0 1.0)))
      ('right  (cons (* render-aspect-ratio  2.0) (rand -1.0 1.0)))
      ('top    (cons (* (rand -1.0 1.0) render-aspect-ratio)  2.0))
      ('bottom (cons (* (rand -1.0 1.0) render-aspect-ratio) -2.0)))))

(define random-edges-seq
  (shuffled-sequence 'left 'right 'top 'bottom))

(define edge-coords
  (fn args
    (random-coordinates-from-the-edge (random-edges-seq))))

;;; four panel arrangements ;;;

(define panel-1x1
  ; for compatibility with effects which assume 4 panels
  (list blank blank blank blank))

(define panels-2x2
  (list
    (fx:mask 0.0 0.5 0.5 1.0)    ; top-left
    (fx:mask 0.5 0.5 1.0 1.0)    ; top-right
    (fx:mask 0.0 0.0 0.5 0.5)    ; bottom-left
    (fx:mask 0.5 0.0 1.0 0.5)))  ; bottom-right


;-----------------------------------------------------------
;   Global effects

(define muvee-global-effect
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))


;-----------------------------------------------------------
;   Non-overlapping segment effects
;   (effects at the middle-section of segment)

;;; multi-screen ;;;

(define multi-2x2-fx
  (let ((x (* render-aspect-ratio 0.47))
        (~x (- x)))
    (layers (A)
      ; top-left
      (effect-stack
        (fx:translate-xy ~x 0.47)
        (with-inputs (list A) (fx:scale 0.50)))
      ; top-right
      (effect-stack
        (fx:translate-xy x 0.47)
        (with-inputs (list A) (fx:scale 0.50)))
      ; bottom-left
      (effect-stack
        (fx:translate-xy ~x -0.47)
        (with-inputs (list A) (fx:scale 0.50)))
      ; bottom-right
      (effect-stack
        (fx:translate-xy x -0.47)
        (with-inputs (list A) (fx:scale 0.50))))))

(define multi-3x1-fx
  (let ((x (* render-aspect-ratio 0.63))
        (~x (- x)))
    (layers (A)
      ; left
      (effect-stack
        (fx:translate-xy ~x 0.0)
        (with-inputs (list A) (fx:scale 0.33)))
      ; middle
      (with-inputs (list A) (fx:scale 0.33))
      ; right
      (effect-stack
        (fx:translate-xy x 0.0)
        (with-inputs (list A) (fx:scale 0.33))))))

(define multi-2x1-fx
  (let ((x (* render-aspect-ratio 0.47))
        (~x (- x)))
    (layers (A)
      ; left
      (effect-stack
        (fx:translate-xy ~x 0.0)
        (with-inputs (list A) (fx:scale 0.50)))
      ; right
      (effect-stack
        (fx:translate-xy x 0.0)
        (with-inputs (list A) (fx:scale 0.50))))))

(define random-multi-fx
  (shuffled-sequence multi-2x1-fx multi-2x2-fx multi-3x1-fx))

(define multi
  (fn args
    (let ((multi-fx (random-multi-fx))
          (fx-in  multi-fx)
          (fx-out multi-fx)
          (fx-seg multi-fx))
      (list (list fx-in fx-seg fx-out) (list 1.0 1.0)))))

;;; pulsate to the beat ;;;

(define plain-fx
  (fn (panels)
    (layers (A)
      (with-inputs (list A) (nth 0 panels))
      (with-inputs (list A) (nth 1 panels))
      (with-inputs (list A) (nth 2 panels))
      (with-inputs (list A) (nth 3 panels)))))

(define pulsate-fx
  (fn (panels tl tr bl br)
    (layers (A)
      ; panel 0
      (effect-stack
        (fx:translate-z (0.0 (linear (effect-time 0.02) tl)
                             (linear 1.0 0.0)))
        (with-inputs (list A) (nth 0 panels)))
      ; panel 1
      (effect-stack
        (fx:translate-z (0.0 (linear (effect-time 0.02) tr)
                             (linear 1.0 0.0)))
        (with-inputs (list A) (nth 1 panels)))
      ; panel 2
      (effect-stack
        (fx:translate-z (0.0 (linear (effect-time 0.02) bl)
                             (linear 1.0 0.0)))
        (with-inputs (list A) (nth 2 panels)))
      ; panel 3
      (effect-stack
        (fx:translate-z (0.0 (linear (effect-time 0.02) br)
                             (linear 1.0 0.0)))
        (with-inputs (list A) (nth 3 panels))))))

(define value2loudness
  (fn (value)
    ; we assume that our current analyzer's loudness hints
    ; alternate between 0.25 and 0.75 in the absense of music
    (if (or (= value 0.25) (= value 0.75)) 0.0 value)))

(define random-pulsating-panels
  ; 3 elements are listed here so that there will be
  ; either one or two pulsating panels per picture
  (shuffled-sequence 0.0 0.0 1.0))

(define pulsate-to-the-beat-fx
  (fn (panels)
    (fn (t1 t2 inputs)
      (let ((dur 0.16)
            (offset -0.02)
            (hint-start (+ t1 offset))
            (hint-stop  (- t2 dur)))
        ; check duration between hint-start and hint-stop 
        (if (< hint-start hint-stop)
          ; interval is long enough - pulsate is possible
          (effect@cut-hints-between
            hint-start
            hint-stop
            inputs
            140  ; hints per minute
            0.1  ; hint separation
            (triggered-effect
              (+ time offset)      ; pulsate start time
              (+ time offset dur)  ; pulsate stop time
              (let ((s (* (value2loudness value) 0.5 ENERGY_LEVEL))
                    (s/2 (* s 0.5)))
                (if (> s 0.0)
                  ; pulsate to the beat!
                  (pulsate-fx panels
                              (* (random-pulsating-panels) (rand s/2 s))
                              (* (random-pulsating-panels) (rand s/2 s))
                              (* (random-pulsating-panels) (rand s/2 s))
                              (* (random-pulsating-panels) (rand s/2 s)))
                  ; no music - no pulsate
                  (plain-fx panels)))))
          ;-----
          ; interval not long enough - no pulsate
          ((plain-fx panels) t1 t2 inputs))))))

(define regulated-pulsate-to-the-beat-fx
  (fn (panels)
    ; the more "energetic" the style parameter is set,
    ; the more number of segments pulsate to the beat
    (if (< (rand 0.0 1.0) ENERGY_LEVEL)
      (pulsate-to-the-beat-fx panels)
      (plain-fx panels))))


;-----------------------------------------------------------
;   Pseudo-transitional animated segment effects
;   (effects at the beginning and end of the segment)

;; crash ;;;

(define pre-crash-fx
  (fn (angle-deg)
    (let ((angle-rad (deg->rad angle-deg))
          (diag-rad  (/ (atan (/ render-aspect-ratio))))
          (x (* (cos angle-rad) render-aspect-ratio 2.0))
          (y (* (sin angle-rad) -2.0))
          (move-fn (fn (p) (- 1.0 (pow p 1.5)))))
      (layers (A)
        ; first crashing layer moves towards the center
        (effect-stack
          (fx:translate-xyz ((- x) (fn (p) (* (move-fn p) (- x))))
                            ((- y) (fn (p) (* (move-fn p) (- y))))
                            -0.002)
          (with-inputs (list A)
            (fx:opacity (0.0 (linear 1.0 0.25)))))
        ; second crashing layer moves towards the center
        (effect-stack
          (fx:translate-xyz (x (fn (p) (* (move-fn p) x)))
                            (y (fn (p) (* (move-fn p) y)))
                            -0.001)
          (with-inputs (list A)
            (fx:opacity (0.0 (linear 1.0 0.5)))))))))

(define post-crash-fx
  (fn (angle-deg)
    (let ((angle-rad (deg->rad angle-deg))
          (diag-rad  (/ (atan (/ render-aspect-ratio))))
          (x (* (cos angle-rad) render-aspect-ratio 2.0))
          (y (* (sin angle-rad) -2.0))
          (move-fn (fn (p) (* (sqrt p) -0.25))))
      (layers (A)
        ; first crashed layer evaporates upon impact
        (effect-stack
          (fx:translate-xyz (0.0 (fn (p) (* (move-fn p) (- x))))
                            (0.0 (fn (p) (* (move-fn p) (- y))))
                            -0.002)
          (fx:scale (1.0 (linear 1.0 2.0)))
          (with-inputs (list A)
            (fx:opacity (0.25 (linear 1.0 0.0)))))
        ; second crashed layer evaporates upon impact
        (effect-stack
          (fx:translate-xyz (0.0 (fn (p) (* (move-fn p) x)))
                            (0.0 (fn (p) (* (move-fn p) y)))
                            -0.001)
          (fx:scale (1.0 (linear 1.0 2.0)))
          (with-inputs (list A)
            (fx:opacity (0.5 (linear 1.0 0.0)))))
        ; the fused layer as a result of the crash
        (with-inputs (list A) (fx:opacity 0.999))))))

(define crash
  (fn args
    (let ((angle  (rand -180.0 180.0))
          (fx-in  (pre-crash-fx angle))
          (fx-seg (post-crash-fx angle))
          (fx-out blank))
      (list (list fx-in fx-seg fx-out) (list 0.75 1.0)))))

;;; slide ;;;

(define slide-fx
  (fn (dir)  ; 0 = inward, 1 = outward
    (let ((inwards? (= (% dir 2) 0))
          (x (* (if inwards? -2.0 2.0) render-aspect-ratio))
          
          (center-coord (cons 0.0 0.0))
          (move-coords (fn (edge-coord)
                         (if inwards?
                           (list edge-coord center-coord)
                           (list center-coord edge-coord))))

          (((x0 . y0) (x1 . y1)) (move-coords (cons x 0.0)))
          ((a0 . a1) (if inwards? (cons 0.0 0.999) (cons 0.999 0.0))))
      
      (effect-stack
        (fx:translate-xy (x0 (smoove 0.0 x0 1.0 x1) 30)
                         (y0 (smoove 0.0 y0 1.0 y1) 30))
        (fx:opacity (a0 (linear 1.0 a1)))))))

(define slide
  (fn args
    (let ((fx-in  (slide-fx 0))
          (fx-out (slide-fx 1))
          (fx-seg (regulated-pulsate-to-the-beat-fx panels-2x2)))
      (list (list fx-in fx-seg fx-out) (list 1.0 1.0)))))

;;; ghosts ;;;

(define ghosts-fx
  (fn (panels dir)  ; 0 = inward, 1 = outward
    (let ((inwards? (= (% dir 2) 0))
          
          (center-coord (cons 0.0 0.0))
          (move-coords (fn (edge-coord)
                         (if inwards?
                           (list edge-coord center-coord)
                           (list center-coord edge-coord))))

          (((p0x0 . p0y0) (p0x1 . p0y1)) (move-coords (edge-coords)))
          (((p1x0 . p1y0) (p1x1 . p1y1)) (move-coords (edge-coords)))
          (((p2x0 . p2y0) (p2x1 . p2y1)) (move-coords (edge-coords)))
          (((p3x0 . p3y0) (p3x1 . p3y1)) (move-coords (edge-coords)))
          ((a0 . a1) (if inwards? (cons 0.0 0.999) (cons 0.999 0.0))))
      
      (layers (A)
        ; panel 0
        (effect-stack
          (fx:opacity 0.25)
          (fx:translate-xyz (p0x0 (smoove 0.0 p0x0 0.7 p0x1) 30)
                            (p0y0 (smoove 0.0 p0y0 0.7 p0y1) 30)
                            -0.003)
          (with-inputs (list A) (nth 0 panels)))
        ; panel 1
        (effect-stack
          (fx:opacity 0.25)
          (fx:translate-xyz (p1x0 (smoove 0.1 p1x0 0.8 p1x1) 30)
                            (p1y0 (smoove 0.1 p1y0 0.8 p1y1) 30)
                            -0.002)
          (with-inputs (list A) (nth 1 panels)))
        ; panel 2
        (effect-stack
          (fx:opacity 0.25)
          (fx:translate-xyz (p2x0 (smoove 0.2 p2x0 0.9 p2x1) 30)
                            (p2y0 (smoove 0.2 p2y0 0.9 p2y1) 30)
                            -0.001)
          (with-inputs (list A) (nth 2 panels)))
        ; panel 3
        (effect-stack
          (fx:opacity 0.25)
          (fx:translate-xy (p3x0 (smoove 0.3 p3x0 1.0 p3x1) 30)
                           (p3y0 (smoove 0.3 p3y0 1.0 p3y1) 30))
          (with-inputs (list A) (nth 3 panels)))))))

(define ghosts
  (fn args
    (let ((fx-in  (ghosts-fx panel-1x1 0))
          (fx-out (ghosts-fx panel-1x1 1))
          (fx-seg (regulated-pulsate-to-the-beat-fx panels-2x2)))
      (list (list fx-in fx-seg fx-out) (list 1.0 1.0)))))

;;; splits ;;;

(define splits-fx
  (fn (panels dir)  ; 0 = inward, 1 = outward
    (let ((inwards? (= (% dir 2) 0))
          (center-coord (cons 0.0 0.0))
          (move-coords (fn (edge-coord)
                         (if inwards?
                           (list edge-coord center-coord)
                           (list center-coord edge-coord))))

          (((p0x0 . p0y0) (p0x1 . p0y1)) (move-coords (edge-coords)))
          (((p1x0 . p1y0) (p1x1 . p1y1)) (move-coords (edge-coords)))
          (((p2x0 . p2y0) (p2x1 . p2y1)) (move-coords (edge-coords)))
          (((p3x0 . p3y0) (p3x1 . p3y1)) (move-coords (edge-coords)))
          ((a0 . a1) (if inwards? (cons 0.0 0.999) (cons 0.999 0.0))))
      
      (layers (A)
        ; panel 0
        (effect-stack
          (fx:opacity (a0 (linear 0.7 a1)))
          (fx:translate-xyz (p0x0 (smoove 0.0 p0x0 0.7 p0x1) 30)
                            (p0y0 (smoove 0.0 p0y0 0.7 p0y1) 30)
                            -0.003)
          (with-inputs (list A) (nth 0 panels)))
        ; panel 1
        (effect-stack
          (fx:opacity (a0 (at 0.1 a0) (linear 0.8 a1)))
          (fx:translate-xyz (p1x0 (smoove 0.1 p1x0 0.8 p1x1) 30)
                            (p1y0 (smoove 0.1 p1y0 0.8 p1y1) 30)
                            -0.002)
          (with-inputs (list A) (nth 1 panels)))
        ; panel 2
        (effect-stack
          (fx:opacity (a0 (at 0.2 a0) (linear 0.9 a1)))
          (fx:translate-xyz (p2x0 (smoove 0.2 p2x0 0.9 p2x1) 30)
                            (p2y0 (smoove 0.2 p2y0 0.9 p2y1) 30)
                            -0.001)
          (with-inputs (list A) (nth 2 panels)))
        ; panel 3
        (effect-stack
          (fx:opacity (a0 (at 0.3 a0) (linear 1.0 a1)))
          (fx:translate-xy (p3x0 (smoove 0.3 p3x0 1.0 p3x1) 30)
                           (p3y0 (smoove 0.3 p3y0 1.0 p3y1) 30))
          (with-inputs (list A) (nth 3 panels)))))))

(define splits
  (fn args
    (let ((panels-seq (apply shuffled-sequence panels-2x2))
          (panels (list (panels-seq) (panels-seq) (panels-seq) (panels-seq)))
          (fx-in  (splits-fx panels 0))
          (fx-out (splits-fx panels 1))
          (fx-seg (regulated-pulsate-to-the-beat-fx panels)))
      (list (list fx-in fx-seg fx-out) (list 1.0 1.0)))))


;-----------------------------------------------------------
;   Segment effect selection

(define segment-effect-seq
  ; the effects here are carefully sync'd with the
  ; order of transitions at muvee-transitions below,
  ; because only effects are suitable to work well
  ; with certain transitions
  (looping-sequence slide
                    ghosts
                    splits
                    splits
                    ;---
                    crash
                    splits
                    splits
                    ;---
                    multi
                    ghosts
                    crash
                    splits
                    splits))

(define segment-effect-selector
  (fn (start stop inputs)
    (let (; get the three-part-effects (fx-in,fx-seg,fx-out)
          ; and the in/out duration scaling factors (p1,p2)
          (((fx-in fx-seg fx-out) (p1 p2))
           (if (< (segment-index) muvee-last-segment-index)
             ((segment-effect-seq))  ; use next effect in the sequence
             (slide)))  ; replace last segment with a slide
          
          ; calculate pseudo-transitional animated effect duration
          ; based on Energy Level (min -> 4 beats, max -> 1 beat),
          ; and bound the value to between 0.1s and 45% of the
          ; segment duration (cos we need another 45% for the
          ; animated-out effect, leaving 10% for pure-segment)
          (bound-fn (limiter 0.1 (* (- stop start) 0.45)))
          (factor (- 4.0 (* (- 2.0 ENERGY_LEVEL) 3.0 ENERGY_LEVEL)))
          (in/out-dur (bound-fn (/ (* factor 60.0) (tempo 0.0))))  ; beats->sec
          
          ; calculate start times of the effects
          (t1 (+ start (* p1 in/out-dur)))
          (t2 (- stop (* p2 in/out-dur)))
          ; apply the effects
          (fx1 (fx-in  start t1 inputs))
          (fx2 (fx-seg t1 t2 (list fx1)))
          (fx3 (fx-out t2 stop (list fx2))))
      fx3)))

(define muvee-segment-effect
  (effect-stack
    segment-effect-selector
    (fx:scale 0.82)  ; this must be below segment-effect-selector
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - cut
;   - dissolve
;   - rotate

;;; dissolve ;;;

(define dissolve-tx
  (effect "CrossFade" (A B)))

;;; rotate ;;;

(define simple-rotate-tx
  (fn (dir rounds)
    ; 0=up, 1=down, 2=left, 3=right
    (let ((angle (* (if (= (% dir 2) 0) -180.0 180.0) rounds)))
      (transition-stack
        (if (< dir 2)
          (fx:rotate-x (0.0 (bezier 1.0 angle 0.0 angle)))
          (fx:rotate-y (0.0 (bezier 1.0 angle 0.0 angle))))
        (layers (A B)
          ; Input B
          (effect-stack
            (fx:opacity (0.0 (at 0.5 1.0)))
            (if (< dir 2) (fx:rotate-x 180.0) (fx:rotate-y 180.0))
            (with-inputs (list B)
              (fx:translate-z -0.001)))
          ; Input A
          (with-inputs (list A)
            (fx:opacity (1.0 (at 0.5 0.0)))))))))

(define rotate
  (fn args (apply (simple-rotate-tx (rand 4) 1) args)))

(define rotate3
  (fn args (apply (simple-rotate-tx (rand 4) 3) args)))

;;; transition selection ;;;

(define muvee-transition
  ; the transitions here are carefully sync'd with the
  ; order of effects at segment-effect-sequence above,
  ; because only transitions are suitable to work well
  ; with certain effects
  (effect-selector
    (looping-sequence cut
                      dissolve-tx
                      rotate
                      ;---
                      cut
                      dissolve-tx
                      rotate
                      ;---
                      dissolve-tx
                      dissolve-tx
                      cut
                      rotate
                      rotate3
                      ;---
                      cut)))


;-----------------------------------------------------------
;   Title and credits

(define TITLE_FOREGROUND_FX
  (fn (start stop inputs)
    (let ((~x (* -2.0 render-aspect-ratio))
          (~p (- 1.0 (/ 1.2 (- stop start)))))
      (apply (effect-stack
               (fx:translate-x (0.0 (smoove ~p 0.0 1.0 ~x) 30))
               (fx:opacity (1.0 (at ~p 1.0) (linear 1.0 0.0)))
               (fx:scale 0.82)
               (effect "CropMedia" (A))
               (effect "Perspective" (A)))
             (list start stop inputs)))))

(define CREDITS_FOREGROUND_FX
  (fn (start stop inputs)
    (let ((x (* 2.0 render-aspect-ratio))
          (p (/ 1.2 (- stop start))))
      (apply (effect-stack
               (fx:translate-x (x (smoove 0.0 x p 0.0) 30))
               (fx:opacity (0.0 (linear p 1.0)))
               (fx:scale 0.82)
               (effect "CropMedia" (A))
               (effect "Perspective" (A)))
             (list start stop inputs)))))

(title-section
  (background
    (image "background.jpg"))
  (foreground
    (fx TITLE_FOREGROUND_FX))
  (text
    (align 'right 'bottom)
    (color 255 255 255)
    (font "-24,0,0,0,900,1,0,0,0,3,2,1,34,Tahoma")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 6.0)))

(credits-section
  (background
    (image "background.jpg"))
  (foreground
    (fx CREDITS_FOREGROUND_FX))
  (text
    (align 'right 'bottom)
    (color 255 255 255)
    (font "-24,0,0,0,900,1,0,0,0,3,2,1,34,Tahoma")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 6.0)))
