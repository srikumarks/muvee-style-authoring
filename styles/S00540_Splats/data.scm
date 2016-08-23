;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00540_Splats
;
;   Copyright (c) 2009 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.8125	0.25 1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (continuous-slider	SHAKE_FREQ	0.5	0.0  1.0))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED MUSIC_RESPONSE 0.25)


;-----------------------------------------------------------
;   Global effects
;   - shakes triggered on cut hitns

(define SHAKE_STRENGTH 1.0)

(define shake-fx
  (fn (amplitude)
    (let ((rnd (fn (n) (* (- (* (rand 2) 2) 1) n)))
          (decay (fn (p) (exp (* -5.0 p))))
          (val (* 5.0 amplitude SHAKE_STRENGTH SHAKE_STRENGTH))
          (t (fn (p) (* val (rnd 0.05) (decay p))))
          (r (fn (p) (* val (rnd 1.0) (decay p)))))
      (effect-stack
        (effect "Translate" (A)
                (param "x" (t 0) t 30)
                (param "y" (t 0) t 30))
        (effect "Rotate" (A)
                (param "ez" 1.0)
                (param "degrees" (r 0) r 30))))))

(define triggered-shakes-fx
  (if (> SHAKE_FREQ 0.0)
    ; enable triggered shakes
    (effect@cut-hints
      ; hints sampling rate
      200
      ; hints minimum separation: 20.25, 6.25, 2.25, 0.75, 0.25
      (* (pow 81.0 (- 1.0 SHAKE_FREQ)) 0.25)
      (triggered-effect
        (- time 0.1)
        (+ time (* SHAKE_STRENGTH 2.5))  ; effect duration depends on quake magnitude
        (if (> value 0.9)
          (shake-fx value)
          blank)))
    ; disable triggered shakes
    blank))

(define muvee-global-effect
  (effect-stack
    triggered-shakes-fx
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))


;-----------------------------------------------------------
;   Segment effects
;   - captions

(define muvee-segment-effect muvee-std-segment-captions)


;-----------------------------------------------------------
;   Transitions
;   - crossfade
;   - crossblur
;   - fade to white
;   - splats wipe
;   - splats double wipe
;   - splats overlay
;   - b&w twist zoom

(define crossfade-tx
  (layers (A B)
    ; fade out input A slowly
    (effect-stack
      (effect "Translate" (A)
              (param "z" -0.001))
      (effect "Alpha" ()
              (input 0 A)
              (param "Alpha" 1.0
                     (bezier 1.0 0.0 1.0 2.0))))
    ; fade in input B slowly
    (effect "Alpha" ()
            (input 0 B)
            (param "Alpha" 0.0
                   (bezier 1.0 1.0 2.0 1.0)))))

(define crossblur-tx
  (let ((maxblur 6.0))
    (layers (A B)
      ; blur and fade out input A slowly
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
      ; unblur and fade in input B slowly
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

;;; splats wipe ;;;

(define mask-fx
  (fn (map-file fp-str (r g b) flip-mode)
    (effect "Mask" (A)
            (param "Path" (resource map-file))
            (param "FlipMode" flip-mode)
            (param "ProgramString" fp-str)
            (param "NumParams" 3)
            ; progress
            (param "a0" 0.0 (linear 1.0 1.0))
            (param "r0" 0.0 (linear 1.0 1.0))
            (param "g0" 0.0 (linear 1.0 1.0))
            (param "b0" 0.0 (linear 1.0 1.0))
            ; feather
            (param "a1" 0.05)
            (param "r1" 0.05)
            (param "g1" 0.05)
            (param "b1" 0.05)
            ; border color
            (param "a2" 1.0)
            (param "r2" r)
            (param "g2" g)
            (param "b2" b))))

(define gradient-fade-tx
  (fn (map-file grad-colors flip-mode)
    (layers (A B)
      ; black background to support full-frame gradient fade
      ; between pictures/video with black bars
      ; (slightly above global underlay layer)
      (effect-stack
        (mask-fx map-file GradientFade_Reverse_Normal_ColorBorder grad-colors flip-mode)
        (effect "Alpha" (A) (param "Alpha" 0.999))
        (effect "Translate" (A) (param "z" -0.0005))
        (effect "Fit" (A))
        (effect "PictureQuad" () (param "Path" (resource "backbase.jpg"))))
      ; input B (below input A layer)
      (effect-stack
        (mask-fx map-file GradientFade_Reverse_Normal_ColorBorder grad-colors flip-mode)
        (effect "Alpha" () (input 0 B) (param "Alpha" 0.999)))
      ; input A (between captions layer and input B)
      (effect-stack
        (mask-fx map-file GradientFade_Forward_Normal_ColorBorder grad-colors flip-mode)
        (effect "Alpha" (A) (param "Alpha" 0.999))
        (effect "Translate" () (input 0 A) (param "z" 0.0003))))))

(define gradient-colors
  (shuffled-sequence (list 1.0   1.0   1.0)    ; white
                     (list 0.988 0.706 0.082)  ; yellow
                     (list 0.988 0.741 0.188)  ; orange
                     (list 0.0   0.0   0.0)))  ; black

(define gradient-maps
  (let ((make-path (fn (file) (format "gradients/" file))))
    (apply shuffled-sequence
           (map make-path
                (list-files (resource (make-path "*.png")))))))

(define splats-wipe-tx
  (effect-selector
    (fn args
      (gradient-fade-tx (gradient-maps)
                        (gradient-colors)
                        (rand FlipMode_None FlipMode_Random)))))

;;; splats double wipe ;;;

(define gradient-fade-to-intermediate-fx
  (fn (map-file grad-colors flip-mode ifx dir)
    (let ((reverse? (= (% dir 2) 1))
          (fpstr (list GradientFade_Forward_Normal_ColorBorder
                       GradientFade_Reverse_Normal_ColorBorder))
          (gradient-fade-fpstr0 (nth (if reverse? 1 0) fpstr))
          (gradient-fade-fpstr1 (nth (if reverse? 0 1) fpstr)))
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (layers (A)
          ; black background to support full-frame gradient fade
          ; between pictures/video with black bars
          ; (slightly above global underlay layer)
          (effect-stack
            (mask-fx map-file gradient-fade-fpstr1 grad-colors flip-mode)
            (effect "Translate" (A) (param "z" -0.0005))
            (effect "Fit" (A))
            (effect "PictureQuad" () (param "Path" (resource "backbase.jpg"))))
          ; intermediate (below input0 layer)
          (effect-stack
            (mask-fx map-file gradient-fade-fpstr1 grad-colors flip-mode)
            ifx)
          ; input0 (between captions layer and intermediate)
          (effect-stack
            (mask-fx map-file gradient-fade-fpstr0 grad-colors flip-mode)
            (effect "Translate" () (input 0 A) (param "z" 0.001))))))))

(define intermediate-images
  (apply shuffled-sequence
         (map (fn (f)
                (effect "PictureQuad" ()
                        (param "Quality" Quality_Normal)
                        (param "Path" (resource (format "overlays" f "/012.png")))))
              (list "01" "02" "03" "04" "05" "06" "07" "08"))))

(define splats-double-wipe-tx
  (effect-selector
    (fn args
      (let ((grad (gradient-maps))
            (col  (gradient-colors))
            (flip (rand FlipMode_None FlipMode_Random))
            (ifx  (intermediate-images)))
        (transition-stack
          (effect-stack
            (remap-time 0.0 0.5 (gradient-fade-to-intermediate-fx grad col flip ifx 0))
            (remap-time 0.5 1.0 (gradient-fade-to-intermediate-fx grad col flip ifx 1)))
          cut)))))

;;; splats overlay ;;;

(define rapid-overlay-fx
  (fn (path seq)
    (layers (A)
      A
      (effect-stack
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (effect "Translate" (A)
                (param "z" 0.002))
        (effect "RapidOverlay" ()
                (param "Path" (resource path))
                (param "Sequence" seq)
                (param "Quality" Quality_Normal))))))

(define overlays
  (apply random-sequence
         (map (fn (n) (format "overlays" n))
              (list "01" "02" "03" "04" "05" "06" "07" "08"))))

(define splats-overlay-tx
  (effect-selector
    (fn (start stop inputs)
      (let ((dp (/ 12/30 (- stop start)))
            ;(p0 (max (- 0.5 dp) 0.0))
            (p1 (min (+ 0.5 dp) 1.0))
            (seq (overlays)))
        (transition-stack
          (remap-time 0.5 p1 (rapid-overlay-fx seq Sequence_Reversed))
          cut)))))

;;; b&w twist zoom ;;;

(define high-contrast-grayscale-fpstr (format
"!!ARBfp1.0
TEMP texfrag, resultColor;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;"
Greyscale_Body
"PARAM solidgray = { 0.5, 0.5, 0.5, 1.0 };
LRP resultColor, 1.5, resultColor, solidgray;
MOV resultColor.a, texfrag.a;
MOV result.color, resultColor; 
END"))

(define high-contrast-grayscale-fx
  (effect "FragmentProgram" (A)
          (param "GlobalMode" 1)
          (param "ProgramString" high-contrast-grayscale-fpstr)))

(define twist-zoom-fx
  (fn (power dir)
    (let ((zoom (fn (t)
                  (+ (* (exp (* -6.0 t))
                        (- (pow 4 power) 0.75))
                     1.0)))
          (twist (fn (t)
                   (* (exp (* -6.0 t))
                      90 power dir))))
      (effect-stack
        (effect "Scale" (A)
                (param "x" (zoom 0.0) zoom 30)
                (param "y" (zoom 0.0) zoom 30))
        (effect "Rotate" (A)
                (param "ez" 1.0)
                (param "degrees" (twist 0.0) twist 30))))))

(define b&w-twist-zoom-tx
  (effect-selector
    (fn (start stop inputs)
      (let ((pref-stop (min (+ (/ 0.5 (- stop start)) 0.5) 1.0)))
        (layers (A B)
          (effect "Alpha" ()
                  (input 0 A)
                  (param "Alpha" 1.0 (at 0.5 0.0)))
          (effect-stack
            (remap-time 0.5 pref-stop
                        (effect-stack
                          high-contrast-grayscale-fx
                          (twist-zoom-fx 1.0 (- (* (rand 2) 2) 1))))
            (effect "Alpha" ()
                    (input 0 B)
                    (param "Alpha" 0.0 (at 0.5 1.0)))))))))

;;; transition selection ;;;

(define muvee-transition
  (select-effect/loudness
    (step-tc 0.0 (effect-selector
                   (shuffled-sequence crossblur-tx
                                      crossblur-tx
                                      crossfade-tx
                                      crossfade-tx))
             0.5 (effect-selector
                   (shuffled-sequence splats-overlay-tx
                                      splats-wipe-tx
                                      splats-double-wipe-tx))
             0.9 (effect-selector
                   (shuffled-sequence fast-fade-to-white-tx
                                      fast-fade-to-white-tx
                                      b&w-twist-zoom-tx
                                      b&w-twist-zoom-tx)))))


;-----------------------------------------------------------
;   Title and credits

(define LAYOUT_X0
  (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) 0.31 0.37))

(title-section
  (background
    (image "background.jpg"))
  (text
    (align 'center 'center)
    (color 37 32 5)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Impact")
    (layout (LAYOUT_X0 0.50) (0.90 0.90))))

(credits-section
  (background
    (image "background.jpg"))
  (text
    (align 'center 'center)
    (color 37 32 5)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Impact")
    (layout (LAYOUT_X0 0.50) (0.9 0.90))))

;;; transitions between title/credits and body ;;;

(define title/credits-tx
  (effect-selector
    (fn args
      (gradient-fade-tx "gradients/004.png"
                        (list 0.0 0.0 0.0)  ; black
                        (rand FlipMode_None FlipMode_Random)))))

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition title/credits-tx title/credits-tx-dur)

(muvee-body-credits-transition title/credits-tx title/credits-tx-dur)
