;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00539_Tech
;
;   Copyright (c) 2009 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.625	0.25 1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (continuous-slider	GLITCH_FREQ	0.5	0.0  1.0)
  (one-of-few		FILM_COLOR	Color	(Color  BW  Bleached  Embers))
  (switch		TV_SCAN_LINES	off)) 


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED MUSIC_RESPONSE 0.3)


;-----------------------------------------------------------
;   Global definitions

(load (resource "techlib.scm"))

(define FOVY 20.0)  ; narrow fovy angle to reduce wide-angle distortion

(define DOORS (box ()))


;-----------------------------------------------------------
;   Global effects
;   - television on (from black to first segment)
;   - television off (from last segment to black)

(define television-on-and-off-fx
  (effect-selector
    (fn (start stop inputs)
      (let ((dp (/ 0.6 (- stop start))))  ; 0.6-sec effect
        (effect-stack
          (remap-time 0.0        dp  television-on-fx)
          (remap-time (- 1.0 dp) 1.0 television-off-fx))))))

(define muvee-global-effect
  (effect-stack
    television-on-and-off-fx
    (effect "CropMedia" (A))
    (effect "Perspective" (A)
            (param "fovy" FOVY))))


;-----------------------------------------------------------
;   Segment effects
;   - television scanlines overlay
;   - television glitches triggered on cut hints
;   - video wall 2x2 (after animated doors wipe)
;   - film color
;   - captions

(define bleached-fpstr (format
; high-contrast desaturation
"!!ARBfp1.0
TEMP texfrag, resultColor;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MUL texfrag.a, texfrag.a, fragment.color.a;
PARAM rWeight = { 0.7586, 0.6094, 0.0802, 1.0 };
PARAM gWeight = { 0.4086, 0.9594, 0.0802, 1.0 };
PARAM bWeight = { 0.4086, 0.6094, 0.4302, 1.0 };
PARAM kWeight = { 0.6666, 0.6666, 0.6666, 1.0 };
DP3 resultColor.r, texfrag, rWeight;
DP3 resultColor.g, texfrag, gWeight;
DP3 resultColor.b, texfrag, bWeight;
LRP resultColor, 1.333, resultColor, kWeight;
MOV resultColor.a, texfrag.a;
MOV result.color, resultColor;
END"))

(define embers-fpstr (format
; warm tones
"!!ARBfp1.0
TEMP texfrag, resultColor;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MUL texfrag.a, texfrag.a, fragment.color.a;
PARAM ember = { 0.5, 0.8, 1.0, 1.0 };
LRP resultColor, 1.6, texfrag, ember;
ADD resultColor.r, resultColor.r, 0.3;
MUL resultColor.b, resultColor.b, 0.3;
MOV resultColor.a, texfrag.a;
MOV result.color, resultColor;
END"))

(define color-fx
  (let ((fpstr (case FILM_COLOR
                 ('BW        ColorMode_Greyscale)
                 ('Bleached  bleached-fpstr)
                 ('Embers    embers-fpstr)
                 (_          ()))))
    (if (!= fpstr ())
      ; enable film color
      (effect "FragmentProgram" (A)
              (param "GlobalMode" 1)
              (param "ProgramString" fpstr))
      ; disable film color
      blank)))

(define scanlines-fx
  (if (= TV_SCAN_LINES 'on)
    ; enable scan lines
    (layers (A)
      A
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.05))
        (effect "Translate" (A)
                (param "z" 0.0006))
        (effect "Scale" (A)
                (param "x" (/ render-aspect-ratio 16/9)))  ; fit width to 4:3 or 16:9
        (effect "PictureQuad" ()
                (param "Path" (resource "lines.png")))))
    ; disable scan lines
    blank))

(define triggered-glitches-fx
  (if (> GLITCH_FREQ 0.0)
    ; enable triggered glitches
    (effect@cut-hints
      ; hints sampling rate
      200
      ; hints minimum separation: 20.25, 6.25, 2.25, 0.75, 0.25
      (* (pow 81.0 (- 1.0 GLITCH_FREQ)) 0.25)
      (triggered-effect
        (- time 0.2)
        (+ time 0.2)  ; glitch interval is 0.4s
        (if (> (loudness time) 0.75)
          (let ((dir (shuffle (list value 0.0))))  ; either horiz or vert direction
            (television-glitch-fx (nth 0 dir) (nth 1 dir) ColorMode_Desaturated 0.9 0.3 0.25))
          blank)))
    ; disable triggered glitches
    blank))

;;; quarter inputs ;;;

(define quarter-input-fx
  (fn (dx dy)
    (effect-stack
      (effect "Translate" (A)
              (param "x" dx)
              (param "y" dy))
      (effect "Scale"()
              (input 0 A)
              (param "x" 0.5)
              (param "y" 0.5)))))

(define two-by-two-fx
  (let (((x ~x y ~y . _) (translation-offset-params 'center)))
    (layers (A)
      (quarter-input-fx ~x  y)
      (quarter-input-fx  x  y)
      (quarter-input-fx ~x ~y)
      (quarter-input-fx  x ~y))))

(define after-doors-transition?
  (fn (fx)
    (effect-selector
      (fn (start stop inputs)
        (let ((doors (collect (DOORS)
                              (fn ((dstart . _))
                                (< (fabs (- dstart start)) 0.001)))))
          ; check if this segment is immediately after "doors" transition
          (if (> (length doors) 0) fx blank))))))

;;; segment effect selection ;;;

(define muvee-segment-effect
  (effect-stack
    (after-doors-transition? two-by-two-fx)  ; z=0
    triggered-glitches-fx   ; z=0, 0.0007, 00008
    scanlines-fx  ; z=0.0006
    color-fx  ; z=0
    muvee-std-segment-captions))  ; z=0.0005


;-----------------------------------------------------------
;   Transitions
;   - crossfade
;   - crossblur
;   - fade to white
;   - animated doors wipe
;   - television tune
;   - television switch
;   - television shatter + television on
;   - cut

(define crossfade-tx
  (layers (A B)
    ; fade out input A
    (effect-stack
      (effect "Translate" (A)
              (param "z" -0.001))
      (effect "Alpha" ()
              (input 0 A)
              (param "Alpha" 1.0
                     (bezier 1.0 0.0 1.0 2.0))))
    ; fade in input B
    (effect "Alpha" ()
            (input 0 B)
            (param "Alpha" 0.0
                   (bezier 1.0 1.0 2.0 1.0)))))

(define crossblur-tx
  (let ((maxblur 6.0))
    (layers (A B)
      ; blur and fade out input A
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "Blur" (A)
                (param "Amount" 0.0
                       (bezier 1.0 1.0 (* maxblur 2.0) maxblur)))
        (effect "Alpha" ()
                (input 0 A)
                (param "Alpha" 1.0
                       (bezier 1.0 0.0 1.0 2.0))))
      ; unblur and fade in input B
      (effect-stack
        (effect "Blur" (A)
                (param "Amount" maxblur
                       (bezier 1.0 0.0 maxblur (* maxblur 2.0))))
        (effect "Alpha" ()
                (input 0 B)
                (param "Alpha" 0.0
                       (bezier 1.0 1.0 2.0 1.0)))))))

(define fast-fade-to-white-tx
  (layers (A B)
    ; show input A for first half of effect
    (effect "Alpha" ()
            (input 0 A)
            (param "Alpha" 1.0 (at 0.5 0.0)))
    ; show input B for second half of effect
    (effect "Alpha" ()
            (input 0 B)
            (param "Alpha" 0.0 (at 0.5 1.0)))
    ; color overlay with varying opacity
    (effect-stack
      (effect "Translate" (A)
              (param "z" 0.001))
      (effect "ColorQuad" ()
              (param "a" 0.0
                     (bezier 0.5 1.0 0.0 -2.0)
                     (bezier 1.0 0.0 -2.0 0.0))
              (param "r" 1.0)
              (param "g" 1.0)
              (param "b" 1.0)))))

(define sound-fx
  (fn (sfx vol)
    (effect "Alpha" (A)
            (sound sfx
                   start: 0.0
                   stop: 1.0
                   volume: vol
                   fade-out: 0.1))))

;;; animated doors wipe ;;;

(define add-depth-fx
  (fn (delta-z)
    (let ((tangent (tan (deg->rad (* FOVY 0.5))))
          (scale (- 1.0 (* tangent delta-z))))
      (effect-stack
        (effect "Translate" (A)
                (param "z" delta-z))
        (effect "Scale" (A)
                (param "x" scale)
                (param "y" scale))))))
  
(define dial-fx
  (fn (in/out)
    (layers (A)
      A
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        ; bring it to a point nearest to the viewer
        ; and still within perspective clipping planes:
        ;   (- (/ (tan (deg->rad (* FOVY 0.5)))) ZNEAR)
        (add-depth-fx 5.57128)
        ; rescale to quarter-size
        (effect "Scale" (A)
                (param "x" 0.5)
                (param "y" 0.5))
        ; dial overlays
        (effect "RapidOverlay" ()
                (param "Path" (resource "dial"))
                (param "Sequence" (if (= in/out 'in) Sequence_Normal Sequence_Reversed))
                (param "Quality" Quality_Normal))))))

(define random-doors
  (shuffled-sequence doors-slide-corners
                     doors-slide-top-bottom
                     doors-slide-left-right
                     doors-hinge-top-bottom
                     doors-hinge-left-right
                     doors-slide-hinge-top-bottom
                     doors-slide-hinge-left-right
                     doors-hinge-center-spin
                     doors-hinge-center-radiate
                     doors-double-hinge-horiz-center
                     doors-drop
                     doors-drop))

(define doors-wipe-tx
  (effect-selector
    (fn (start stop inputs)
      ; keep track of "doors" transition interval
      (DOORS (join (DOORS) (list (cons start stop))))
      ; now apply the "doors" transition
      (transition-stack
        (let ((doors-fx (random-doors)))
          (effect-stack
            ; dial (z=2.3)
            (remap-time 0.0 1.0 (sound-fx "sfx/dial.mvx" -3.0))
            (remap-time 0.0 0.5 (dial-fx 'in))
            (remap-time 0.5 1.0 (dial-fx 'out))
            ; doors (z=0.005)
            ; doors closing
            (remap-time 0.30 0.45 (doors-fx 'in))
            ; doors remain shut
            (remap-time 0.45 1.00 (sound-fx "sfx/close.mvx" 0.0))
            (remap-time 0.45 0.75 doors-center-static)
            ; doors opening
            (remap-time 0.75 1.00 (sound-fx "sfx/open.mvx" 3.0))
            (remap-time 0.75 1.00 (doors-fx 'out))
            ; translate behind and scale up user's material
            ; to prevent z-fighting with animated doors
            (add-depth-fx -4.0)))
        cut))))

;;; television ;;;

(define television-tune-tx
  (let ((inverted-v (fn (t) (- 1.0 (fabs (- 1.0 t t)))))
        (inverted-u (fn (t) (- (* 4.0 t) (* 4.0 t t)))))
    (transition-stack
      (effect-stack
        (sound-fx "sfx/static.mvx" 6.0)
        (effect-stack
          (television-static-fx  inverted-v)
          (television-distort-fx inverted-u)))
      cut)))

(define television-switch-tx
  (effect-selector
    (fn (start stop inputs)
      (let ((dt (/ 0.1 (- stop start)))
            (t0 (max (- 0.5 dt) 0.0))
            (t1 (min (+ 0.5 dt) 1.0))
            (on (fn args 1.0)))
        (transition-stack
          (remap-time t0 t1 (television-static-fx on))
          cut)))))

;;; shatter ;;;

(define television-shatter+switch-on-tx
  (effect-selector
    (fn (start stop inputs)
      (let ((p0 (- 1.0 (/ 0.4 (- stop start))))  ; slightly faster than initial "switch-on" effect duration
            (size (+ (* (rand 3) 2) 5))  ; need odd number so that centre piece flies towards viewer
            (axis (nth (rand 2) (list "RotateX" "RotateY"))))
        (layers (A B)
          (effect-stack
            (remap-time p0 1.0 television-on-fx)
            (effect "Alpha" ()
                    (input 0 B)
                    (param "Alpha" 0.0 (at p0 1.0))))
          (remap-time 0.48 0.85 (effect "ShatterSquares" ()
                                        (input 0 A)
                                        (param "DistanceZ" 4.0)
                                        (param "FadeOut" 1)
                                        (param "GridSize" size)
                                        (param axis 1.5))))))))

;;; transition selection ;;;

(define muvee-transition
  (select-effect/loudness
    (step-tc 0.0 (effect-selector
                   (shuffled-sequence crossblur-tx
                                      crossblur-tx
                                      crossfade-tx
                                      crossfade-tx))
             0.4 (effect-selector
                   (looping-sequence doors-wipe-tx
                                     television-tune-tx
                                     doors-wipe-tx
                                     television-tune-tx
                                     television-shatter+switch-on-tx
                                     doors-wipe-tx))
             0.9 (effect-selector
                   (shuffled-sequence cut
                                      cut
                                      fast-fade-to-white-tx
                                      television-switch-tx
                                      television-switch-tx)))))


;-----------------------------------------------------------
;   Title and credits

(define LAYOUT_X
  (if (< (fabs (- render-aspect-ratio 4/3)) 0.1)
    (cons 0.09 0.68)
    (cons 0.19 0.64)))

(define fade-to-black-fx
  (fn (start-fade)
    (layers (A)
      A
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.1))
        (effect "ColorQuad" ()
                (param "a" 0.0
                       (at start-fade 0.0)
                       (bezier 1.0 1.0 0.0 0.0))
                (param "hexColor" 0xFF000000))))))

(define fade-from-black-fx
  (fn (stop-fade)
    (layers (A)
      A
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.1))
        (effect "ColorQuad" ()
                (param "a" 1.0
                       (bezier stop-fade 0.0 1.0 1.0)
                       (at 1.0 0.0))
                (param "hexColor" 0xFF000000))))))

(title-section
  (audio-clip "sfx/tech.mvx" gaindb: 0.0)
  (background
    (video "title.wmv"))
  (foreground
    (fx (fade-to-black-fx 0.6)))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-18,0,0,0,400,0,0,0,0,3,2,1,34,Arial")
    (layout ((first LAYOUT_X) 0.22) ((rest LAYOUT_X) 0.79))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)
    (custom-parameters
      (param "FadeText" 0.0
             (at (effect-time 1.2) 0.0)
             (linear (effect-time 2.2) 1.0)))))

(credits-section
  (audio-clip "sfx/tech.mvx" gaindb: 0.0)
  (background
    (video "credits.wmv"))
  (foreground
    (fx (fade-from-black-fx 0.4)))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-18,0,0,0,400,0,0,0,0,3,2,1,34,Arial")
    (layout ((first LAYOUT_X) 0.22) ((rest LAYOUT_X) 0.79))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)
    (custom-parameters
      (param "FadeText" 1.0
             (at (effect-time 2.8) 1.0)
             (linear (effect-time 3.8) 0.0)))))
