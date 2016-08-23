;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00541_Motion
;
;   Copyright (c) 2009 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (one-of-few		BACKGROUND	Input	(Input  None  Color))
  (color		TOP_GRADIENT	0x000000)
  (color		BOTTOM_GRADIENT	0x222222))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED MUSIC_RESPONSE)


;-----------------------------------------------------------
;   Global definitions

(load (resource "motionlib.scm"))

(define FOVY 30.0)

(define MINZ -30.0)

(define USER_MEDIA_OFFSET 0.0)

(define VIDEO_WALL_TX (box ()))


;-----------------------------------------------------------
;   Global effects
;   - color gradient background
;   - volumetric lights triggered on flash hints

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

(define color-gradient-background-fx
  (let ((tangent (tan (deg->rad (* FOVY 0.5))))
        (zfar (- (/ tangent) MINZ)))
    (effect-stack
      (effect "CropMedia" (A))
      (effect "Perspective" (A)
              (param "fovy" FOVY)
              (param "zFar" zfar))
      (if (= BACKGROUND 'Color)
        ; enable color gradient background
        (layers (A)
          (effect-stack
            (add-depth-fx (+ MINZ 0.1))  ; prevent z-fighting with title/credits background
            (effect "ColorGradient" ()
                    (param "TopLeftHex"     TOP_GRADIENT)
                    (param "TopRightHex"    TOP_GRADIENT)
                    (param "BottomLeftHex"  BOTTOM_GRADIENT)
                    (param "BottomRightHex" BOTTOM_GRADIENT)))
          A)
        ; disable color gradient background
        ; (user-content background is shown at segment-effect level)
        blank))))

(define triggered-volumetric-lights-fx
  (effect@flash-hints
    200
    2.0
    (triggered-effect
      (- time 0.05)
      (+ time 2.95)
      (effect "VolumetricLights" (A)
              (param "NumberOfLayers" 12)
              (param "TextureIncrement" 0.01)
              (param "TranslateIncrement" 0.01)
              (param "AlphaDecay" 0.90)
              (param "Animation" value
                     (fn (p) (* (exp (* -5.0 p)) value)))))))

(define muvee-global-effect
  (effect-stack
    triggered-volumetric-lights-fx
    color-gradient-background-fx))


;-----------------------------------------------------------
;   Effects and transition coordination
;
;   Sequences here are carefully synchronized with 
;   one another so as to produce the following
;   looping set of effects and transitions:
;     (1) strips(in,out)        >>[fade]<<
;     (2) strips(in,out)        >>[fade]<<
;     (3) strips(in,out)        >>[fade]<<
;     (4) strips(in)+plain(out) >>[roll]<<
;     (5) plain(in)+strips(out) >>[fade]<<
;     (6) spin(in,out)          >>[fade]<<
;     (7) spin(in,out)          >>[fade]<<
;     (8) spin(in,out)          >>[fade]<<
;     (9) strips(in)+plain(out) >>[fly]<<
;    (10) plain(in)+strips(out) >>[fade]<<

(define to-spin-or-not-to-spin?
  (looping-sequence () () () () ()  ; (1-5)
                    T T T           ; (6-8)
                    () ()))         ; (9-10)

(define to-move-in-or-move-out?
  (looping-sequence
    (cons T  T)    ; (1,6) in and out
    (cons T  T)    ; (2,7) in and out
    (cons T  T)    ; (3,8) in and out
    (cons T ())    ; (4,9) in only
    (cons () T)))  ; (5,10) out only


;-----------------------------------------------------------
;   Segment effects
;   - zoomed-grayscale background
;   - motion grid
;   - captions

;;; motion grid ;;;

(define min-motion-dur
  (+ (* (pow (- AVERAGE_SPEED 1.0) 2.0) 3.0) 0.5))

(define strips
  ; a collection of strips-like effects for motion grid
  (shuffled-sequence blinds interleave yoyo))

(define move
  (fn (fx dir)
    ; camera movement for motion grid
    (effect-stack (camera-move-fx dir) (fx dir))))

(define grid-fx
  (effect-selector
    (fn args
      (let ((first? (= (segment-index) 0))
            (last? (= (segment-index) muvee-last-segment-index))
            ; increment sequences to keep effect loops in sync
            (spin? (to-spin-or-not-to-spin?))
            (move? (to-move-in-or-move-out?))
            ; determine the types of grid effects to use
            ; (i.e. plain, strips or spin) for incoming
            ; and outgoing portions of current segment
            (in? (first move?))
            (out? (rest move?))
            (infx? (or in? first?))
            (outfx? (or out? last?))
            ((infx outfx) (cond
                            (first? (list plain (strips)))  ; plain first segment
                            (last?  (list (strips) plain))  ; plain last segment
                            ((and in? out? spin?) (let ((s (spin))) (list s s)))  ; spin in and out
                            (_ (list (strips) (strips))))))  ; strips
        ; call motionlib function to generate grid effects
        (motion-grid-fx min-motion-dur
                        (if infx? (layers (A)) blank)
                        (if infx? (move infx 'in) blank)     ; move camera inwards
                        (if outfx? (move outfx 'out) blank)  ; move camera outwards
                        (if outfx? (layers (A)) blank))))))

;;; zoomed-grayscale background ;;;

(define dark-grayscale-fpstr (format
; dark grayscale
"!!ARBfp1.0
PARAM luma = { 0.299, 0.587, 0.114, 1.0 };
TEMP texfrag, gray;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MUL texfrag.a, texfrag.a, fragment.color.a;
DP3 gray.r, texfrag, luma;
MUL gray.r, gray.r, 0.2;
MOV gray.a, texfrag.a;
SWZ result.color, gray, r,r,r,a;
END"))

(define zoomed-grayscale-fx
  (fn (blur zoom)
    (effect-stack
      (effect "FragmentProgram" (A)
              (param "GlobalMode" 0)
              (param "ProgramString" dark-grayscale-fpstr))
      (effect "Scale" (A)
              (param "x" zoom)
              (param "y" zoom)))))

(define user-content-background-fx
  (effect-stack
    (zoomed-grayscale-fx 4.0 6.0)
    (add-depth-fx (+ MINZ 2.1))))

(define outside-video-wall-interval
  (fn (fx)
    (fn (start stop inputs)
      (let ((tfx (effect "Alpha" (A) (param "Alpha" 0.0)))
            (~= (fn (a b) (< (fabs (- a b)) 0.001)))
            ; get non-overlapping interval with video wall transitions
            (non-overlap-interval (collect (VIDEO_WALL_TX)
                                           (fn ((istart . istop))
                                             (and (< istart stop) (> istop start)))
                                           (fn ((istart . istop))
                                             (cons (if (~= istart start) istop start)
                                                   (if (~= istop stop) istart stop)))))
            ((t0 . t1) (if non-overlap-interval
                         (first non-overlap-interval)
                         (cons start stop))))
        (assert (< t0 t1))
        ; apply fx at non-overlap-interval, and
        ; transparent effects to overlap interval
        (fx t0 t1
            (list (tfx t1 stop
                       (list (tfx start t0 inputs)))))))))

(define background+grid-fx
  (effect-stack
    (effect "Alpha" (A)
            (param "Alpha" 0.999))
    (effect "Translate" (A)
            (param "z" USER_MEDIA_OFFSET))
    (layers (A)
      ; background
      (if (= BACKGROUND 'Input)
        ; enable user-content background
        (with-inputs (list A) (outside-video-wall-interval user-content-background-fx))
        ; diable user-content background
        (fn args))
      ; foreground: user's content
      (with-inputs (list A) grid-fx))))

(define muvee-segment-effect
  (effect-stack
    background+grid-fx
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - crossfade
;   - video wall: roll through multiple inputs
;   - video wall: fly across multiple inputs

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

(define with-independent-background-layer
  (fn (tx)
    (effect-selector
      (fn (start stop inputs)
        (if (= BACKGROUND 'Input)
          ; enable independent background layer
          (do
            ; keep track of transition interval
            (VIDEO_WALL_TX (join (VIDEO_WALL_TX) (list (cons start stop))))
            ; independent background layer
            (layers (A B)
              ; background: crossfade
              (with-inputs (list A B) (transition-stack
                                        user-content-background-fx
                                        crossfade-tx))
              ; foreground: tx
              (with-inputs (list A B) tx)))
          ; disable independent background layer
          ; and just apply tx
          tx)))))

(define transition-motion
  ; refer to "Effects and transition coordination" section above
  (looping-sequence
    crossfade-tx    ; (1)
    crossfade-tx    ; (2)
    crossfade-tx    ; (3)
    (with-independent-background-layer roll-through-inputs-tx)  ; (4)
    crossfade-tx    ; (5)
    crossfade-tx    ; (6)
    crossfade-tx    ; (7)
    crossfade-tx    ; (8)
    (with-independent-background-layer fly-across-inputs-tx)    ; (9)
    crossfade-tx))  ; (10)

(define muvee-transition
  (effect-selector transition-motion))


;-----------------------------------------------------------
;   Title and credits

(define hex->triplet-complement
  (fn (hex)
    (let ((aa? (> hex 0xFFFFFF))
          (rrggbb (if aa? (% hex 0x1000000) hex))
          (ggbb   (% rrggbb 0x10000))
          (red    (trunc (/ rrggbb 0x10000)))
          (green  (trunc (/ ggbb 0x100)))
          (blue   (% ggbb 0x100)))
      (map (fn (x) (- 255 x)) (list red green blue)))))

(define TEXT_COLOR
  (if (= BACKGROUND 'Color)
    (hex->triplet-complement BOTTOM_GRADIENT)
    (list 255 255 255)))

(title-section
  (foreground
    (fx color-gradient-background-fx))
  (text
    (align 'left 'bottom)
    (apply color TEXT_COLOR)
    (fade-out)
    (font "-22,0,0,0,400,1,0,0,0,3,2,1,34,Franklin Gothic Medium")
    (layout (0.10 0.12) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 1.5)))

(credits-section
  (foreground
    (fx color-gradient-background-fx))
  (text
    (align 'left 'bottom)
    (apply color TEXT_COLOR)
    (fade-in)
    (font "-22,0,0,0,400,1,0,0,0,3,2,1,34,Franklin Gothic Medium")
    (layout (0.10 0.12) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 1.5)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition crossfade-tx title/credits-tx-dur)

(muvee-body-credits-transition crossfade-tx title/credits-tx-dur)
