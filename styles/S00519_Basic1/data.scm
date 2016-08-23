;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00519_Basic1
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)
  (one-of-few		FILM_COLOR	Sepia	(Sepia  BW  Color))
  (continuous-slider	FILM_QUALITY	0.5	0.0  1.0))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed
;   - transfer curves subdomain mapping

(let ((tc-mid (+ (* AVERAGE_SPEED 0.5) 0.25))
      (MUSIC_RESPONSE 0.5)
      (tc-dev (* MUSIC_RESPONSE 0.25)))
  (map-tc-subdomain (- tc-mid tc-dev) (+ tc-mid tc-dev)))

(segment-durations 4.0)

(segment-duration-tc 0.00  8.00
                     0.25  4.00
                     0.50  1.00
                     0.75  0.25
                     1.00  0.125)

(time-warp-tc 0.00  0.125
              0.25  0.25
              0.375 0.50
              0.50  1.00
              1.00  1.00)

(preferred-transition-duration 1.5)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00  8.00
                        0.25  4.00
                        0.50  1.00
                        0.75  0.25
                        1.00  0.125)


;-----------------------------------------------------------
;   Global effects
;   - color tint

(define perspective-fx
  (effect "Perspective" (A)))

(define color-tint-fx
  (case FILM_COLOR
    ('BW    (effect "Greyscale" (A) (param "GlobalMode" 0)))
    ('Sepia (effect "Sepia" (A) (param "GlobalMode" 0)))
    (_      blank)))

(define muvee-global-effect
  (effect-stack
    color-tint-fx
    perspective-fx))


;-----------------------------------------------------------
;   Segment effects
;   - lines and scratches
;   - noise and vignette
;   - captions

(define FILM_DIRTINESS (- 1.0 FILM_QUALITY))

(define dirty-fx
  (effect-stack
    (layers (A)
      A
      ; our lines and scratch contain translucent pixels which may
      ; show up if they are above the fade-to-black transition layer      
      (effect "OldMovieLines" ()
              (param "Alpha" FILM_DIRTINESS)
              (param "Red"   0.0)
              (param "Green" 0.0)
              (param "Blue"  0.0)
              (param "LineGaps" 80.0)
              (param "LineDistance" 0.1)
              (param "NumLines" (trunc (* 10.0 FILM_DIRTINESS))))
      (effect "OldMovieScratches" ()
              (param "Alpha" (- 1.0 FILM_QUALITY))
              (param "Red"   0.0)
              (param "Green" 0.0)
              (param "Blue"  0.0)
              (param "NumScratches" (trunc (* 8.0 FILM_DIRTINESS))))
      ; overlays creates an illusion of flickering and film noise
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.001))
        (effect "Scale" (A)
                (param "y" 1.01))
        (effect "Alpha" (A)
                (param "Alpha" (* (pow FILM_DIRTINESS 0.3) 0.999)))
        (effect "RapidOverlay" ()
                (param "Path" (resource "vignette"))
                (param "FrameRate" 16.0)
                (param "FlipMode" FlipMode_Random)
                (param "Sequence" Sequence_Random))))))

(define muvee-segment-effect
  (effect-stack
    dirty-fx
    muvee-std-segment-captions))


;-----------------------------------------------------------
;   Transitions
;   - fade to black, when music is soft
;   - cut

(define fade-to-black-tx
  (layers (A B)
    ; show input A for first half of effect
    (effect "Alpha" ()
            (input 0 A)
            (param "Alpha" 1.0 (at 0.5 0.0)))
    ; show input B for second half of effect
    (effect "Alpha" ()
            (input 0 B)
            (param "Alpha" 0.0 (at 0.5 1.0)))
    ; color fade in and fade out
    (effect-stack
      (effect "Translate" (A)
              (param "z" 0.001))
      (effect "ColorQuad" ()
              (param "a" 0.0
                     (bezier 0.5 1.0 0.0 0.0)
                     (bezier 1.0 0.0 1.0 1.0))
              (param "r" 0.0)
              (param "g" 0.0)
              (param "b" 0.0)))))

(define muvee-transition
  (select-effect/loudness
    (step-tc 0.0 fade-to-black-tx
             0.5 cut)))


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    dirty-fx
    color-tint-fx
    perspective-fx))

(title-section
  (audio-clip "projector.mvx" gaindb: -3.0)
  (background
    (image "background.jpg"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (typewriter)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (audio-clip "projector.mvx" gaindb: -3.0)
  (background
    (image "background.jpg"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (typewriter)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

; pseudo-cut transition between title/credits and
; muvee body allows the music to be interleaved
; with the sound effects without cutting abruptly

(muvee-title-body-transition fade-to-black-tx 1.0)

(muvee-body-credits-transition fade-to-black-tx 1.0)
