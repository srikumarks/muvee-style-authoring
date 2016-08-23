;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00510_SportHex
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.75	0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE	0.75	0.0  1.0)
  (continuous-slider	HEX_SIZE	0.125	0.0  0.5)
  (continuous-slider	HEX_OVERLAYS	0.25	0.0  1.0)
  (switch		TV_SCAN_LINES	on))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed
;   - transfer curves subdomain mapping

(let ((tc-mid (+ (* AVERAGE_SPEED 0.5) 0.25))
      (tc-dev (* MUSIC_RESPONSE 0.25)))
  (map-tc-subdomain (- tc-mid tc-dev) (+ tc-mid tc-dev)))

(segment-durations 4.0 4.0 2.0 2.0)

(segment-duration-tc 0.00 8.00
                     0.25 4.00
                     0.75 1.00
                     1.00 0.25)

(time-warp-tc 0.00 0.10
              0.25 0.25
              0.50 1.00
              1.00 1.00)

(preferred-transition-duration 1.0)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 3.00
                        0.25 1.50
                        0.75 0.60
                        1.00 0.30)


;-----------------------------------------------------------
;   Global effects
;   - hexagonal overlays triggered on flash hints
;   - television scan lines overlay

;;; scan lines ;;;

(define image-overlay-fx
  (fn (file opacity)
    (layers (A)
      A
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.003))
        (effect "Alpha" (A)
                (param "Alpha" opacity))
        (effect "PictureQuad" ()
                (param "Path" (resource file)))))))

(define scanlines-fx
  (if (= TV_SCAN_LINES 'on)
    (image-overlay-fx "lines.png" 0.125)
    blank))

;;; triggered overlays ;;;

(define hex-overlays-seq
  (apply looping-sequence
         (map (fn (n) (format "overlays" n))
              (list "01" "02" "03" "04"))))

(define rapid-overlay-fx
  (fn (path flip seq opacity)
    (layers (A)
      A
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.002))
        (effect "Alpha" (A)
                (param "Alpha" opacity))
        (effect "RapidOverlay" ()
                (param "Path" (resource path))
                (param "FlipMode" flip)
                (param "Sequence" seq))))))

(define triggered-hex-overlays-fx
  (let ((dur 25/30)
        (sep (* (pow 16 (- 1.0 HEX_OVERLAYS)) dur)))
    (if (> HEX_OVERLAYS 0.0)
      (effect@flash-hints
        120  ; sampling rate hints per minute
        sep  ; min separation of hints
        (triggered-effect
           time          ; start time
           (+ time dur)  ; stop time
           ; rapid overlay whose opacity varies proportionately to hint strength
           (if (< (+ time dur) muvee-duration-secs)
             (rapid-overlay-fx (hex-overlays-seq)
                               (rand 4)
                               Sequence_Normal
                               (+ (* value 0.3) 0.1))
             blank)))
      blank)))

(define muvee-global-effect
  (effect-stack
    scanlines-fx
    triggered-hex-overlays-fx
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))


;-----------------------------------------------------------
;   Segment effects
;   - captions

(define muvee-segment-effect muvee-std-segment-captions)


;-----------------------------------------------------------
;   Transitions
;   - bottom 35% of music loudness:
;     - blur
;   - between 35% and 80% of music loudness:
;     - hexagonal gradient wipe
;     - fade-to-white
;     - cut
;   - top-20% of music loudness:
;     - hexagonal explode
;     - cut

(define fade-to-white-tx
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
              (param "r" 1.0)
              (param "g" 1.0)
              (param "b" 1.0)))))

(define blur-tx
  (let ((maxblur 7.0))
    (layers (A B)
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "Blur" ()
                (input 0 A)
                (param "Amount" 0.0
                       (linear 1.0 maxblur))))
      (effect-stack
        (effect "Alpha" (B)
                (param "Alpha" 0.0
                       (linear 1.0 1.0)))
        (effect "Blur" ()
                (input 0 B)
                (param "Amount" maxblur
                       (linear 1.0 0.0)))))))

;;; hexagonal explode ;;;

(define random-shatter-pattern
  (shuffled-sequence 0 1 2 3 4 5 6))

(define shatter+fade+quake-tx
  (let ((move-offset (- 1.0 (* HEX_SIZE 0.6)))
        (polygon-length (+ HEX_SIZE 0.025))
        (delta-z -2.0)
        (fovy 45.0)  ; assumes 45" fovy
        (tangent (tan (deg->rad (* fovy 0.5))))
        (scale (- 1.0 (* tangent delta-z))))
    (layers (A B)
      ; quake whose amplitude decays over time
      (effect-stack
        (effect "Translate" (A)
                (param "x" 0.0 (fn (p) (* (rand -0.2 0.2) (- 1.0 p))) 30)
                (param "y" 0.0 (fn (p) (* (rand -0.2 0.2) (- 1.0 p))) 30)
                (param "z" delta-z))
        (effect "Scale" ()
                (input 0 B)
                (param "x" (* scale 1.1) (linear 1.0 scale))
                (param "y" (* scale 1.1) (linear 1.0 scale))))
      ; fade in from white
      (effect "ColorQuad" ()
              (param "a" 1.0 (bezier 1.0 0.0 1.0 1.0)))
      ; shatter into pieces and fly forward
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.001))
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (effect "Shatter" ()
                (input 0 A)
                (param "z" -2.5)
                (param "LastStartTime" 0.25)
                (param "MoveOffset" move-offset)
                (param "PolygonLength" polygon-length)
                (param "RevPerProgress" 1.5)
                (param "Pattern" (random-shatter-pattern))
                (param "Reverse" 0))))))

(define reverse-shatter+fade+quake-tx
  (let ((move-offset (- 1.0 (* HEX_SIZE 0.6)))
        (polygon-length (+ HEX_SIZE 0.025))
        (delta-z -2.0)
        (fovy 45.0)  ; assumes 45" fovy
        (tangent (tan (deg->rad (* fovy 0.5))))
        (scale (- 1.0 (* tangent delta-z))))
    (layers (B A)  ; quick way to swap inputs
      (effect-stack
        ; quake whose amplitude increases over time
        (effect "Translate" (A)
                (param "x" 0.0 (fn (p) (* (rand -0.2 0.2) p)) 30)
                (param "y" 0.0 (fn (p) (* (rand -0.2 0.2) p)) 30)
                (param "z"delta-z))
        ; quake whose amplitude increases over time
        (effect "Scale" ()
                (input 0 B)
                (param "x" scale (linear 1.0 (* scale 1.1)))
                (param "y" scale (linear 1.0 (* scale 1.1)))))
      ; fade out to white
      (effect "ColorQuad" ()
              (param "a" 0.0 (bezier 1.0 1.0 0.0 0.0)))
      ; shatter into pieces and fly forward
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.001))
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (effect "Shatter" ()
                (input 0 A)
                (param "z" -2.5)
                (param "LastStartTime" 0.25)
                (param "MoveOffset" move-offset)
                (param "PolygonLength" polygon-length)
                (param "RevPerProgress" 1.5)
                (param "Pattern" (random-shatter-pattern))
                (param "Reverse" 1))))))

(define hexagonal-explode
  (effect-selector
    (random-sequence shatter+fade+quake-tx
                     reverse-shatter+fade+quake-tx)))

;;; hexagonal gradient wipe ;;;

(define hex-gradients-seq
  (apply looping-sequence
         (map (fn (n) (format "hex" n))
              (list "01" "02" "03" "04" "05" "06" "07" "08"))))

(define rapid-gradient-wipe-tx
  (fn (path flip)
    (layers (A B)
      A
      ; fade out to white
      (effect "ColorQuad" ()
              (param "a" 0.0 (bezier 1.0 1.0 0.0 0.0)))
      ; rapid gradient
      (effect-stack
        (effect "Translate" (A)
                (param "z" 0.001))
        (effect "Alpha" (A)
                (param "Alpha" 0.999))
        (effect "RapidGradient" ()
                (input 0 B)
                (param "Path" (resource path))
                (param "FlipMode" flip))))))

(define hexagonal-wipes
  (fn args
    (apply (rapid-gradient-wipe-tx (hex-gradients-seq) (rand 4))
           args)))

;;; transition selection ;;;

(define muvee-transition
  (select-effect/loudness
    (step-tc 0.00 blur-tx
             0.35 (effect-selector
                    (random-sequence hexagonal-wipes
                                     cut
                                     cut
                                     fade-to-white-tx
                                     fade-to-white-tx))
             0.80 (effect-selector
                    (looping-sequence hexagonal-explode
                                      cut)))))


;-----------------------------------------------------------
;   Title and credits

(define FOREGROUND_FX
  (effect-stack
    scanlines-fx
    (effect "Perspective" (A))))

(title-section
  (audio-clip "hex.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 241 132 6)
    (font "-22,0,0,0,800,0,0,0,0,3,2,1,34,Trebuchet MS")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (audio-clip "hex.mvx" gaindb: -3.0)
  (background
    (video "background.wmv"))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 241 132 6)
    (font "-22,0,0,0,800,0,0,0,0,3,2,1,34,Trebuchet MS")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))
