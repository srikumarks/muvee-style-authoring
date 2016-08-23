;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00518_Cube
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	BEAT_RESPONSE	0.5	0.0  1.0)
  (continuous-slider	BOUNCINESS	0.5	0.0  1.0)
  (continuous-slider	HOVER		0.5	0.0  1.0)
  (one-of-few		THEME		None	(None  ThemeA  ThemeB)))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration-beats
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration-beats 18.0) 2.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 2.00
                     0.35 1.50
                     0.75 0.50
                     1.00 0.25)

(time-warp-tc 0.00 0.30
              0.25 0.75
              0.65 1.00
              1.00 1.00)

(define average-transition-duration-beats
  (+ (* base-duration-beats 9.0) 1.0))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        1.00 0.50)


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


;-----------------------------------------------------------
;   Global effects
;   - hover
;   - pulsate, based on cut-hints
;   - background video

(define AR render-aspect-ratio)
(define ~AR (- AR))

;;; background video ;;;

(define video-loop-fx
  (let (((vid . dur) (case THEME
                       ('ThemeA (cons "background01.wmv" 10.0))
                       ('ThemeB (cons "background02.wmv" 10.0))
                       ('None   (cons () 0.0)))))
    (if vid
      (fn (start stop inputs)
        (video-loop-track (resource vid) 16/9 start stop 0 dur 0 () ()))
      blank)))

(define background-fx
  (let ((delta-z -6.0)
        (fovy 20.0)  ; set to 20" fovy for lesser distortion during spins
        (tangent (tan (deg->rad (* fovy 0.5))))
        (scale (- 1.0 (* tangent delta-z)))
        (zfar (- (/ tangent) delta-z)))
    (effect-stack
      (effect "CropMedia" (A))
      (effect "Perspective" (A)
              (param "fovy" fovy)
              (param "zFar" zfar))
      (if (= THEME 'None)
        ; no background video needed
        blank
        ; background video
        (layers (A)
          (effect-stack
            (fx:translate-z delta-z)
            (fx:scale scale)
            video-loop-fx)
          A)))))

;;; pulsate ;;;

(define value2loudness
  (fn (value)
    ; we assume that our current analyzer's loudness hints
    ; alternate between 0.25 and 0.75 in the absense of music
    (if (or (= value 0.25) (= value 0.75)) 0.0 value)))

(define pulsate-to-the-beat-fx
  (effect@cut-hints
    140
    0.1
    (triggered-effect
      (- time 0.02)
      (+ time 0.14)
      (let ((s (+ (* (value2loudness value) 0.25 BEAT_RESPONSE) 1.0)))
        (fx:scale (1.0 (linear (effect-time 0.02) s)
                       (linear 1.0 1.0)))))))

;;; hover ;;;

(define hover-fx
  (let ((hover-fn (fn (amplitude ang-freq)
                    (fn (p)
                      (* (sin (* ang-freq muvee-duration-secs p))
                         HOVER
                         amplitude)))))
    (effect-stack
      (fx:translate-z {- ~AR 2.0})
      (fx:rotate-x (0.0 (hover-fn  8.0 0.5)))
      (fx:rotate-y (0.0 (hover-fn 22.0 0.7)))
      (fx:rotate-z (0.0 (hover-fn  5.0 0.3)))
      (fx:translate-z AR))))

;;; global effect ;;;

(define muvee-global-effect
  (effect-stack
    background-fx
    pulsate-to-the-beat-fx
    hover-fx))


;-----------------------------------------------------------
;   Segment-level effects
;   - for non-overlapping segments, draw the cube and fill
;     all faces with the current input
;   - for overlapping segments (where transition happens),
;     don't draw the cube and just return the input as is,
;     because transitions will take care of drawing the cube
;   - captions

(define face-fx
  (layers (A)
    ; surface
    (effect-stack
      (effect "Fit" (A))  ; cubeface aspect ratio must be 1:1
      (fx:image "cubeface.jpg"))
    ; content
    (effect-stack
      (fx:translate-z 0.001)
      (with-inputs (list A) (fx:scale 0.98)))))

(define cube-fx
  ; takes the current input (a flat surface) and builds all
  ; six faces of the cube (i.e. the same input is repeated)
  (layers (A)
    ; left face ;
    (effect-stack
      (fx:translate-xyz ~AR 0.0 ~AR)
      (fx:rotate-x 180.0)  ; invert vertically
      (with-inputs (list A) (fx:rotate-y -90.0)))
    ; back face ;
    (effect-stack
      (fx:translate-z {+ ~AR ~AR})
      (with-inputs (list A) (fx:rotate-y 180.0)))
    ; right face ;
    (effect-stack
      (fx:translate-xyz AR 0.0 ~AR)
      (fx:rotate-x 180.0)  ; invert vertically
      (with-inputs (list A) (fx:rotate-y 90.0)))
    ; top face ;
    (effect-stack
      (fx:translate-xyz 0.0 1.0 ~AR)
      (fx:rotate-y 90.0)
      (fx:rotate-x -90.0)
      (with-inputs (list A) (fx:scale-y AR)))
    ; bottom face ;
    (effect-stack
      (fx:translate-xyz 0.0 -1.0 ~AR)
      (fx:rotate-y 90.0)
      (fx:rotate-x 90.0)
      (with-inputs (list A) (fx:scale-y AR)))
    ; front face ;
    A))

(define cube-on-pure-segments
  (fn (start stop inputs)
    (let ((s (segment-index))
          (pure-start (if (> s 0)
                        (+ (segment-stop-time (- s 1)) 0.001)
                        start))
          (pure-stop  (if (< s muvee-last-segment-index)
                        (- (segment-start-time (+ s 1)) 0.001)
                        stop))
          ; this is the flat surface which will be
          ; applied to all faces of the cube
          (theface (apply face-fx (list start stop inputs))))
      (if (> (- pure-stop pure-start) 1/30)
        ; cube-fx uses input from face-fx to build the cube
        (cube-fx pure-start pure-stop (list theface))
        ; but if the duration for this effect is shorter than
        ; one frame, then we won't see both face-fx and cube-fx,
        ; and for this fringe case, we just apply face-fx
        theface))))

(define muvee-segment-effect
  (effect-stack
    cube-on-pure-segments
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - replace cube with different inputs on different faces,
;     such that the front face is always the current input,
;     the destination face is the next input, and the rest
;     the faces show either current or next input depending
;     on the spinning action
;   - spin the cube to the destination face, with decaying
;     oscillation towards the end

(define underdamped-oscillation-fn
  (fn (z)
    (let ((norm (pow (- (+ z z) (* z z)) -0.5))
          (wd (* (floor (* 10 z)) pi))
          (w0 (* wd norm))
          (B  (* (- 1.0 z) norm)))
      ; formula:
      ;   f(t) = [A cos(wd*t) + B sin(wd*t)] * e^((z-1)*w0*t))
      ;   where    z = (0.0, 1.0],      0=critical damping, 1=no damping
      ;         norm = 1/sqrt(z+z-z*z),
      ;           wd = |10*z| * pi,     natural damped frequency
      ;           w0 = wd * norm,       natural undamped frequency
      ;            B = (1-z) * norm,
      ;            A = 1.0
      (fn (t)
        (* (+ (cos (* wd t))
              (* B (sin (* wd t))))
           (exp (* (- z 1.0) w0 t)))))))

(define bounce-fn
  (let ((oscillation-fn (underdamped-oscillation-fn
                          (+ (* BOUNCINESS 0.6) 0.1))))
    (fn (p)
      (- 1.0 (* (if (> p 0.9)
                  (- 10 (* 10 p))  ; forced damping after 90%
                  1.0)             ; no damping before 90%
                (oscillation-fn p))))))

(define spin-fx
  (fn (x y z)
    (effect-stack
      (fx:translate-z ~AR)
      (fx:rotate-x (0.0 (fn (p) (* (bounce-fn p) x)) 30))
      (fx:rotate-y (0.0 (fn (p) (* (bounce-fn p) y)) 30))
      (fx:rotate-z (0.0 (fn (p) (* (bounce-fn p) z)) 30))
      (fx:translate-z AR))))

(define cube-tx
  ; similar to cube-fx above, but this builds the cube faces
  ; with either input A or B in any desirable orientation,
  ; and it requires that input A and B to be flat surfaces
  (fn ((left back right top bottom)
       (inv-left? inv-back? inv-right? inv-top? inv-bottom?))
    (layers (A B)
      ; left face ;
      (effect-stack
        (fx:translate-xyz ~AR 0.0 ~AR)
        (if inv-left? (fx:rotate-x 180.0) (fx:rotate-x 0.0))
        (with-inputs (list left) (fx:rotate-y -90.0)))
      ; back face ;
      (effect-stack
        (fx:translate-z {+ ~AR ~AR})
        (with-inputs (list back)
          (if inv-back? (fx:rotate-x 180.0) (fx:rotate-y 180.0))))
      ; right face ;
      (effect-stack
        (fx:translate-xyz AR 0.0 ~AR)
        (if inv-right? (fx:rotate-x 180.0) (fx:rotate-x 0.0))
        (with-inputs (list right) (fx:rotate-y 90.0)))
      ; top face ;
      (effect-stack
        (fx:translate-xyz 0.0 1.0 ~AR)
        (if inv-top? (fx:rotate-y -90.0) (fx:rotate-y 90.0))
        (fx:rotate-x -90.0)
        (with-inputs (list top) (fx:scale-y AR)))
      ; bottom face ;
      (effect-stack
        (fx:translate-xyz 0.0 -1.0 ~AR)
        (if inv-bottom? (fx:rotate-y -90.0) (fx:rotate-y 90.0))
        (fx:rotate-x 90.0)
        (with-inputs (list bottom) (fx:scale-y AR)))
      ; front face ;
      A)))

;;; spinning actions ;;;

(define spin-up-up-tx
  (transition-stack
    (spin-fx -180.0 0.0 0.0)
    (cube-tx (list B B B A ((random-sequence A B)))
             (list () T () () ()))))
             
(define spin-down-down-tx
  (transition-stack
    (spin-fx 180.0 0.0 0.0)
    (cube-tx (list B B B ((random-sequence A B)) A)
             (list () T () () ()))))

(define spin-left-left-tx
  (transition-stack
    (spin-fx 0.0 -180.0 0.0)
    (cube-tx (list A B A B B)
             (list T () () () ()))))

(define spin-right-right-tx
  (transition-stack
    (spin-fx 0.0 180.0 0.0)
    (cube-tx (list A B A B B)
             (list () () T () ()))))

(define spin-up-left-tx    
  (transition-stack
    (spin-fx -180.0 90.0 0.0)
    (cube-tx (list B A B B B)
             (list T T T () ()))))

(define spin-up-right-tx
  (transition-stack
    (spin-fx -180.0 -90.0 0.0)
    (cube-tx (list B A B B B)
             (list T T T T ()))))

(define spin-down-left-tx
  (transition-stack
    (spin-fx 180.0 90.0 0.0)
    (cube-tx (list B A B B B)
             (list T T T T ()))))

(define spin-down-right-tx
  (transition-stack
    (spin-fx 180.0 -90.0 0.0)
    (cube-tx (list B A B B B)
             (list T T T () T))))

;;; transition selection ;;;

(define muvee-transition
  (effect-selector
    (shuffled-sequence spin-up-up-tx
                       spin-down-down-tx
                       spin-left-left-tx
                       spin-right-right-tx
                       spin-up-left-tx
                       spin-up-right-tx
                       spin-down-left-tx
                       spin-down-right-tx)))


;-----------------------------------------------------------
;   Title and credits

(title-section
  (audio-clip "cube.mvx" gaindb: -3.0)
  (background
    (video "background00.wmv"))
  (text
    (align 'right 'top)
    (color 255 255 255)
    (fade-out)
    (font "-21,0,0,0,400,0,0,0,0,3,2,1,34,Verdana")
    (layout (0.25 0.10) (0.90 0.80))
    (soft-shadow  dx: 2.0  dy: 2.0  size: 4.0)))

(credits-section
  (audio-clip "cube.mvx" gaindb: -3.0)
  (background
    (video "background00.wmv"))
  (text
    (align 'right 'top)
    (color 255 255 255)
    (fade-in)
    (font "-21,0,0,0,400,0,0,0,0,3,2,1,34,Verdana")
    (layout (0.25 0.10) (0.90 0.80))
    (soft-shadow  dx: 2.0  dy: 2.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define dissolve-tx
  (effect "CrossFade" (A B)))

(muvee-title-body-transition dissolve-tx 2.0)
 
(muvee-body-credits-transition dissolve-tx 2.0)
