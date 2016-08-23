;muvee-style-authoring.googlecode.com
;muSE v2
;
;   techlib
;
;   Copyright (c) 2009 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Television

;;; on and off ;;;

(define television-on-fx
  (let ((bounciness 0.5)
        (on 0.5)
        (vx (+ (* bounciness 0.2) 1.0))
        (vy (+ (* bounciness 1.0) 1.0)))
    (effect-stack
      (effect "Scale" (A)
              (param "x" 0.0
                     (bezier on  0.9 0.1 -2.2)
                     (bezier 1.0 1.0 vx vx))
              (param "y" 0.0
                     (linear 0.1 0.01)
                     (linear on  0.01)
                     (bezier 1.0 1.0 vy vy)))
      (layers (A)
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.001))
          (effect "ColorQuad" ()
                  (input 0 A)
                  (param "a" 1.0
                         (linear on  1.0)
                         (bezier 1.0 0.0 -1.0 0.0))))
        A))))

(define television-off-fx
  (let ((bounciness 0.5)
        (off 0.35)
        (vx (+ (* bounciness 0.2) 1.0))
        (vy (+ (* bounciness 1.0) 1.0)))
    (effect-stack
      (effect "Scale" (A)      
              (param "x" 1.0
                     (bezier off 0.9 vx vx)
                     (bezier 1.0 0.0 -2.2 0.1))
              (param "y" 1.0
                     (bezier off 0.01 vy vy)
                     (linear 0.9 0.01)
                     (linear 1.0 0.0)))
      (layers (A)
        (effect-stack
          (effect "Translate" (A)
                  (param "z" 0.001))
          (effect "ColorQuad" ()
                  (input 0 A)
                  (param "a" 0.0
                         (bezier off 1.0 0.0 -1.0)
                         (linear 1.0 1.0))))
        A))))

;;; glitch ;;;

(define television-glitch-fx
  (fn (horiz vert colormode intensity scanlines rate)
    (let ((f (fn _ (if (> (rand 1.0) rate) 0.0 1.0)))
          (sx (+ (* (rand horiz) 4.0) 1.0))
          (sy (+ (* (rand vert) 4.0) 1.0))
          (dx (* (- sx 1.0) render-aspect-ratio 0.8))
          (dy (* (- sy 1.0) 0.8)))
      (layers (A)
        A
        (effect-stack
          ; glitch animation
          (effect "Alpha" (A)
                  (param "Alpha" 0.0 f 16))
          (layers ()
            ; rescaled and translated user content
            (effect-stack
              (effect "Alpha" (A)
                      (param "Alpha" intensity))
              (effect "Translate" (A)
                      (param "x" (rand (- dx) dx))
                      (param "y" (rand (- dy) dy))
                      (param "z" 0.0007))
              (effect "Scale" (A)
                      (param "x" sx)
                      (param "y" sy))
              (effect "FragmentProgram" ()
                      (input 0 A)
                      (param "GlobalMode" 1)
                      (param "ProgramString" colormode)))
            ; scan lines overlay
            (effect-stack
              (effect "Alpha" (A)
                      (param "Alpha" scanlines))
              (effect "Translate" (A)
                      (param "z" 0.0008))
              (effect "PictureQuad" ()
                      (param "Quality" Quality_Normal)
                      (param "Path" (resource "lines.png"))))))))))

;;; static ;;;

(define television-static-fx
  (fn (amount)
    (let ((chrominance (fn (t) (exp (* -8.0 (amount t)))))
          (content-mix (fn (t) (- 1.0 (amount t))))
          (static-mix  (fn (t) (amount t))))
      (layers (A)
        ; user's content
        (effect-stack
          (effect "Alpha" (A)
                  (param "Alpha" (content-mix 0.0) content-mix))
          (effect "FragmentProgram" ()
                  (input 0 A)
                  (param "GlobalMode" 1)
                  (param "ProgramString" RGBtoYUV)
                  (param "NumParams" 2)
                  (param "r1" 1.0)  ; constant luminance
                  (param "g1" (chrominance 0) chrominance)
                  (param "b1" (chrominance 0) chrominance)))
        ; static overlay
        (effect-stack
          (effect "Alpha" (A)
                  (param "Alpha" (static-mix 0.0) static-mix))
          (effect "Translate" (A)
                  (param "z" 0.001))
          (effect "RapidOverlay" ()
                  (param "FrameRate" 30.0)
                  (param "FlipMode" FlipMode_Random)
                  (param "Sequence" Sequence_Random)
                  (param "Quality" Quality_Normal)
                  (param "Path" (resource "static"))))))))

;;; distort ;;;

(define television-distort-fx
  (fn (amount)
    (let ((translate (fn (x) (- (* 0.5 x) 1.0)))
          (waveyfunc (fn (r t) (sin (* r pi t))))
          (amplitude (fn (t) (* (amount t) (amount t))))
          (f1 (fn (r x) (fn (p) (+ (translate x) (* (waveyfunc r p) (amplitude p))))))
          (f2 (fn (r x) (fn (p) (- (translate x) (* (waveyfunc r p) (amplitude p) 4)))))
          (f3 (fn (r x) (fn (p) (+ (translate x) (* (waveyfunc r p) (amplitude p) 6)))))
          ((r0 r1 r2 r3 r4) (map (fn _ (rand 10 30)) (list 0 1 2 3 4))))
      (effect-stack
        ; cheating wrap-around by
        ; duplicating input left and right
        ; with minor overlap between them
        (layers (A)
          (effect "Translate" ()
                  (input 0 A)
                  (param "x" (+ (* -2.0 render-aspect-ratio) 0.01))
                  (param "z" -0.001))
          (effect "Translate" ()
                  (input 0 A)
                  (param "x" (- (* 2.0 render-aspect-ratio) 0.01))
                  (param "z" -0.001))
          A)
        ; distort waves
        (effect "Distort" (A)
                (param "GridSize" 5)
                (param "p00x" ((f1 r0 0) 0) (f1 r0 0) 30)
                (param "p10x" ((f1 r0 1) 0) (f1 r0 1) 30)
                (param "p20x" ((f1 r0 2) 0) (f1 r0 2) 30)
                (param "p30x" ((f1 r0 3) 0) (f1 r0 3) 30)
                (param "p40x" ((f1 r0 4) 0) (f1 r0 4) 30)
                (param "p01x" ((f2 r1 0) 0) (f2 r1 0) 30)
                (param "p11x" ((f2 r1 1) 0) (f2 r1 1) 30)
                (param "p21x" ((f2 r1 2) 0) (f2 r1 2) 30)
                (param "p31x" ((f2 r1 3) 0) (f2 r1 3) 30)
                (param "p41x" ((f2 r1 4) 0) (f2 r1 4) 30)
                (param "p02x" ((f3 r2 0) 0) (f3 r2 0) 30)
                (param "p12x" ((f3 r2 1) 0) (f3 r2 1) 30)
                (param "p22x" ((f3 r2 2) 0) (f3 r2 2) 30)
                (param "p32x" ((f3 r2 3) 0) (f3 r2 3) 30)
                (param "p42x" ((f3 r2 4) 0) (f3 r2 4) 30)
                (param "p03x" ((f2 r3 0) 0) (f2 r3 0) 30)
                (param "p13x" ((f2 r3 1) 0) (f2 r3 1) 30)
                (param "p23x" ((f2 r3 2) 0) (f2 r3 2) 30)
                (param "p33x" ((f2 r3 3) 0) (f2 r3 3) 30)
                (param "p43x" ((f2 r3 4) 0) (f2 r3 4) 30)
                (param "p04x" ((f1 r4 0) 0) (f1 r4 0) 30)
                (param "p14x" ((f1 r4 1) 0) (f1 r4 1) 30)
                (param "p24x" ((f1 r4 2) 0) (f1 r4 2) 30)
                (param "p34x" ((f1 r4 3) 0) (f1 r4 3) 30)
                (param "p44x" ((f1 r4 4) 0) (f1 r4 4) 30))))))


;-----------------------------------------------------------
;   Doors movement

(define translation-offset-params
  (let ((xnear (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) 2/3 8/9))
        (xfar  (+ xnear render-aspect-ratio))
        (ynear 1/2)
        (yfar  3/2))
    (fn (in/out)
      (cond ((= in/out 'in) (list xfar xnear yfar ynear))
            ((= in/out 'out) (list xnear xfar ynear yfar))
            ((= in/out 'center) (list xnear (- xnear) ynear (- ynear)))
            (_ (list xnear xnear ynear ynear))))))

(define rotation-degrees-params
  (let ((deg0 0.0) (deg1 90.0))
    (fn (in/out)
      (cond ((= in/out 'in)  (list deg1 deg0))
            ((= in/out 'out) (list deg0 deg1))
            (_               (list deg0 deg0))))))

(define rotate-about-axis
  (fn (axis len% deg0 deg1)
    (let (((axtr units axrot) (if (= axis 'vert)
                                (list "x" (* render-aspect-ratio len%) "ey")
                                (list "y" len% "ex"))))
      (effect-stack
        (effect "Translate" (A)
                (param axtr units))
        (effect "Rotate" (A)
                (param axrot 1.0)
                (param "degrees" deg0 (bezier 1.0 deg1 deg0 deg1)))
        (effect "Translate" (A)
                (param axtr (- units)))))))

(define rotate-about-x-then-y
  (fn (ptx% pty% degx0 degx1 degy0 degy1)
    (effect-stack
      (effect "Translate" (A)
              (param "x" (* ptx% render-aspect-ratio))
              (param "y" pty%))
      (effect "Rotate" (A)
              (param "ey" 1.0)
              (param "degrees" degy0 (bezier 1.0 degy1 degy0 degy1)))
      (effect "Rotate" (A)
              (param "ex" 1.0)
              (param "degrees" degx0 (bezier 1.0 degx1 degx0 degx1)))
      (effect "Translate" (A)
              (param "x" (* ptx% render-aspect-ratio -1.0))
              (param "y" (- pty%))))))

(define rotate-about-y-then-x
  (fn (ptx% pty% degx0 degx1 degy0 degy1)
    (effect-stack
      (effect "Translate" (A)
              (param "x" (* ptx% render-aspect-ratio))
              (param "y" pty%))
      (effect "Rotate" (A)
              (param "ex" 1.0)
              (param "degrees" degx0 (bezier 1.0 degx1 degx0 degx1)))
      (effect "Rotate" (A)
              (param "ey" 1.0)
              (param "degrees" degy0 (bezier 1.0 degy1 degy0 degy1)))
      (effect "Translate" (A)
              (param "x" (* ptx% render-aspect-ratio -1.0))
              (param "y" (- pty%))))))

(define move-door
  (fn (quad x0 x1 y0 y1 . rfx)
    (effect-stack
      ; translate from (x0,y0) to (x1,y1)
      (effect "Translate" (A)
              (param "x" x0 (bezier 1.0 x1 x0 x1))
              (param "y" y0 (bezier 1.0 y1 y0 y1))
              (param "z" 0.005))
      ; scale to quarter-size
      (effect "Scale" (A)
              (param "x" 0.5)
              (param "y" 0.5))
      ; apply rotation before translation, if specified
      (if rfx (first rfx) blank)
      ; load door quadrant image
      (effect "SeamlessBackground" ()
              (param "Path" (resource (format "doors/" quad ".png")))
              (param "Quality" Quality_Normal)))))

(define doors-center-static
  (let (((x ~x y ~y) (translation-offset-params 'center)))
    (layers (A)
      (move-door "tl" ~x ~x  y  y)
      (move-door "tr"  x  x  y  y)
      (move-door "bl" ~x ~x ~y ~y)
      (move-door "br"  x  x ~y ~y))))
          
(define doors-slide-corners
  (fn (in/out)
    (let (((x0 x1 y0 y1) (translation-offset-params in/out))
          ((~x0 ~x1 ~y0 ~y1) (list (- x0) (- x1) (- y0) (- y1))))
      (layers (A)
        A
        (move-door "tl" ~x0 ~x1  y0  y1)
        (move-door "tr"  x0  x1  y0  y1)
        (move-door "bl" ~x0 ~x1 ~y0 ~y1)
        (move-door "br"  x0  x1 ~y0 ~y1)))))

(define doors-slide-top-bottom
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((_ _ y0 y1) (translation-offset-params in/out))
          ((~y0 ~y1) (list (- y0) (- y1))))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y0  y1)
        (move-door "tr"  x  x  y0  y1)
        (move-door "bl" ~x ~x ~y0 ~y1)
        (move-door "br"  x  x ~y0 ~y1)))))

(define doors-slide-left-right
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((x0 x1 _ _) (translation-offset-params in/out))
          ((~x0 ~x1) (list (- x0) (- x1))))
      (layers (A)
        A
        (move-door "tl" ~x0 ~x1  y  y)
        (move-door "tr"  x0  x1  y  y)
        (move-door "bl" ~x0 ~x1 ~y ~y)
        (move-door "br"  x0  x1 ~y ~y)))))

(define doors-hinge-left-right
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          (hinge-left  (rotate-about-axis 'vert -1.0 (- deg0) (- deg1)))
          (hinge-right (rotate-about-axis 'vert  1.0 deg0 deg1)))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y hinge-left)
        (move-door "tr"  x  x  y  y hinge-right)
        (move-door "bl" ~x ~x ~y ~y hinge-left)
        (move-door "br"  x  x ~y ~y hinge-right)))))

(define doors-hinge-top-bottom
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          (hinge-top    (rotate-about-axis 'horiz  1.0 (- deg0) (- deg1)))
          (hinge-bottom (rotate-about-axis 'horiz -1.0 deg0 deg1)))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y hinge-top)
        (move-door "tr"  x  x  y  y hinge-top)
        (move-door "bl" ~x ~x ~y ~y hinge-bottom)
        (move-door "br"  x  x ~y ~y hinge-bottom)))))

(define doors-slide-hinge-left-right
  (fn (in/out)
    (let (((_ _ y ~y) (translation-offset-params 'center))
          ((x0 x1 . _) (translation-offset-params in/out))
          ((~x0 ~x1) (list (- x0) (- x1)))
          ((deg0 deg1) (rotation-degrees-params in/out))
          (hinge-left  (rotate-about-axis 'vert -1.0 (- deg0) (- deg1)))
          (hinge-right (rotate-about-axis 'vert  1.0 deg0 deg1)))
      (layers (A)
        A
        (move-door "tl" ~x0 ~x1  y  y hinge-right)
        (move-door "tr"  x0  x1  y  y hinge-left)
        (move-door "bl" ~x0 ~x1 ~y ~y hinge-right)
        (move-door "br"  x0  x1 ~y ~y hinge-left)))))

(define doors-slide-hinge-top-bottom
  (fn (in/out)
    (let (((x ~x _ _) (translation-offset-params 'center))
          ((_ _ y0 y1 . _) (translation-offset-params in/out))
          ((~y0 ~y1) (list (- y0) (- y1)))
          ((deg0 deg1) (rotation-degrees-params in/out))
          (hinge-top    (rotate-about-axis 'horiz  1.0 (- deg0) (- deg1)))
          (hinge-bottom (rotate-about-axis 'horiz -1.0 deg0 deg1)))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y0  y1 hinge-bottom)
        (move-door "tr"  x  x  y0  y1 hinge-bottom)
        (move-door "bl" ~x ~x ~y0 ~y1 hinge-top)
        (move-door "br"  x  x ~y0 ~y1 hinge-top)))))

(define doors-hinge-center-spin
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          ((~deg0 ~deg1) (list (- deg0) (- deg1))))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y
                   (rotate-about-x-then-y  1.0 -1.0  deg0  deg1 ~deg0 ~deg1))
        (move-door "tr"  x  x  y  y
                   (rotate-about-y-then-x -1.0 -1.0 ~deg0 ~deg1 ~deg0 ~deg1))
        (move-door "bl" ~x ~x ~y ~y
                   (rotate-about-y-then-x  1.0  1.0  deg0  deg1  deg0  deg1))
        (move-door "br"  x  x ~y ~y
                   (rotate-about-x-then-y -1.0  1.0 ~deg0 ~deg1  deg0  deg1))))))

(define doors-hinge-center-radiate
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          ((~deg0 ~deg1) (list (- deg0) (- deg1))))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y
                   (rotate-about-x-then-y  1.0 -1.0 ~deg0 ~deg1 ~deg0 ~deg1))
        (move-door "tr"  x  x  y  y
                   (rotate-about-y-then-x -1.0 -1.0 ~deg0 ~deg1  deg0  deg1))
        (move-door "bl" ~x ~x ~y ~y
                   (rotate-about-y-then-x  1.0  1.0  deg0  deg1 ~deg0 ~deg1))
        (move-door "br"  x  x ~y ~y
                   (rotate-about-x-then-y -1.0  1.0  deg0  deg1  deg0  deg1))))))

(define doors-double-hinge-horiz-center
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          ((~deg0 ~deg1) (list (- deg0) (- deg1))))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y
                   (rotate-about-x-then-y  1.0 -1.0  deg0  deg1 ~deg0 ~deg1))
        (move-door "tr"  x  x  y  y
                   (rotate-about-x-then-y -1.0 -1.0  deg0  deg1  deg0  deg1))
        (move-door "bl" ~x ~x ~y ~y
                   (rotate-about-x-then-y  1.0  1.0 ~deg0 ~deg1 ~deg0 ~deg1))
        (move-door "br"  x  x ~y ~y
                   (rotate-about-x-then-y -1.0  1.0 ~deg0 ~deg1  deg0  deg1))))))

(define doors-drop
  (fn (in/out)
    (let (((x ~x y ~y) (translation-offset-params 'center))
          ((deg0 deg1) (rotation-degrees-params in/out))
          ((z0 z1) (if (= in/out 'in) (list 6.0 0.0) (list 0.0 6.0)))
          (rnd (fn (n) (* (rand (- n) n) 0.5)))
          (rfx (fn (x% y%)
                 (effect-stack
                   (effect "Translate" (A)
                           (param "z" z0 (bezier 1.0 z1 z0 z1)))
                   (rotate-about-x-then-y x% y%
                                          (rnd deg0) (rnd deg1)
                                          (rnd deg0) (rnd deg1))))))
      (layers (A)
        A
        (move-door "tl" ~x ~x  y  y (rfx -0.5  0.5))
        (move-door "tr"  x  x  y  y (rfx  0.5  0.5))
        (move-door "bl" ~x ~x ~y ~y (rfx -0.5 -0.5))
        (move-door "br"  x  x ~y ~y (rfx  0.5 -0.5))))))
