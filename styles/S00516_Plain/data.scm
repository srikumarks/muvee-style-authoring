;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00516_Plain
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED		0.5	 0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE		0.5	 0.0  1.0)
  (color		FTC_LOUDNESS_LOW	0x000000)
  (color		FTC_LOUDNESS_HIGH	0xFFFFFF)
  (switch		DISSOLVES_ONLY		off))


;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed
;   - transfer curves subdomain mapping

(let ((tc-mid (+ (* AVERAGE_SPEED 0.5) 0.25))
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
;   Segment effects
;   - captions

(define muvee-segment-effect muvee-std-segment-captions)


;-----------------------------------------------------------
;   Transitions
;   - fade-to-color:
;     - one color for softer parts of the music
;     - another color for louder parts of the music
;       (at constant duration)
;   - dissolve for medium-loud parts of the music
  (define dissolve-tx (layers (A B)
							(effect-stack
							(effect "Translate" (A)
									(param "z" 0.011))
							(effect "Alpha" ()
									(input 0 A)
									(param "Alpha" 0.99 (linear 1.0 0.0))))
									
							(effect-stack
							(effect "Translate" (A)
									(param "z" 0.012))
							(effect "Alpha" ()
									(input 0 B)
									(param "Alpha" 0.0 (linear 1.0 0.99))))))

(define hex->triplet
  (fn (hex)
    (let ((aa? (> hex 0xFFFFFF))
          (rrggbb (if aa? (% hex 0x1000000) hex))
          (ggbb   (% rrggbb 0x10000))
          (red    (trunc (/ rrggbb 0x10000)))
          (green  (trunc (/ ggbb 0x100)))
          (blue   (% ggbb 0x100)))
      (map (fn (x) (* x 1/255)) (list red green blue)))))

(define fade-to-color-tx
  (fn (hex fade-color-dur)
    (fn (start stop inputs)
      (let (; fade color duration, specified in seconds, gets converted
            ; to relative start-stop time within the effect's duration
            (halfcolprog (/ fade-color-dur (- stop start) 2))
            ((p0 . p1) (if (and (> halfcolprog 0.0) (< halfcolprog 0.5))
                         (cons (- 0.5 halfcolprog) (+ 0.5 halfcolprog))
                         (cons 0.0 1.0)))
            ; convert color from hex to rgb normalized values
            ((r g b) (hex->triplet hex)))
        (apply (layers (A B)
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
                                  (at p0 0.0)
                                  (bezier 0.5 1.0 0.0 0.0)
                                  (bezier p1 0.0 1.0 1.0))
                           (param "r" r)
                           (param "g" g)
                           (param "b" b))))
               (list start stop inputs))))))

(define dissolve-or-fade-tx
  (fn (hex fade-color-dur)
    (if (= DISSOLVES_ONLY 'on)
      dissolve-tx
      (fade-to-color-tx hex fade-color-dur))))

(define muvee-transition
  (select-effect/loudness
    (step-tc 0.00 (dissolve-or-fade-tx FTC_LOUDNESS_LOW 0.0)
             0.30 dissolve-tx
             0.80 (dissolve-or-fade-tx FTC_LOUDNESS_HIGH 0.4))))


;-----------------------------------------------------------
;   Title and credits

(title-section
  (background
    (color 0 0 0))
  (foreground 
	(fx (effect "Perspective" (A))))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-out)
    (font "-20,0,0,0,400,0,0,0,0,3,2,1,34,Arial Black")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (background
    (color 0 0 0))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-in)
    (font "-20,0,0,0,400,0,0,0,0,3,2,1,34,Arial Black")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(muvee-title-body-transition dissolve-tx 1.0)

(muvee-body-credits-transition dissolve-tx 1.0)
