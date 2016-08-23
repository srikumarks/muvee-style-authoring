;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00522_Basic4
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters  
  (one-of-many			MOTION			All	(All Curve Linear Simple Spin))
  (continuous-slider	AVERAGE_SPEED	0.5	0.0  1.0)  
  (continuous-slider    RIPPLES			0.25   0.0   1.0)
  (continuous-slider	RIPPLE_DURATION 0.25 0.0  1.0)
  (color		TOP_BACKGROUND_GRADIENT		0x000000)
  (color		BOTTOM_BACKGROUND_GRADIENT	0xFFFFFF))
  

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
    (effect "Alignment" (A) (param "alignment" Alignment_Bottom))  ; bottom-align user's media
    (effect "Translate" (A) (param "z" -1.0))
    (effect "Perspective" (A) (param "zFar" 50.0))))

;-----------------------------------------------------------
;   Segment-level effects
;   - show pictures and videos on a reflective surface with
;     moving polygons
;   - captions in front of the input

(define reflect-fx
  (fn (reflectivity)
    (effect "ReflectAndRipples" (A)
            (param "floorAlpha" (- 1.0 reflectivity))
			(param "RippleFrequency" (* 20 RIPPLES RIPPLES))
			(param "EnableRipples"  1 )
			(param "RippleHeight"   0.1 )
			(param "RippleDuration" (+ 0.95 (* RIPPLE_DURATION 0.05)))
			(param "TopBackgroundColor" TOP_BACKGROUND_GRADIENT )
			(param "BottomBackgroundColor" BOTTOM_BACKGROUND_GRADIENT))))			


(define reflection-fx   (reflect-fx 0.3))

(define captions-fx
  (layers (A)
    A
    (effect-stack
      (effect "Translate" (A)
              (param "z" 0.4))
      (effect "Alpha" (A)
              (param "Alpha" 0.99))
      muvee-segment-captions)))

(define muvee-global-effect (effect-stack   view-fx    
											reflection-fx))
	
(define muvee-segment-effect captions-fx )



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
		

;;Simple		
(define slide-tx1 
			(layers (A B)
			(effect "Translate" ()
				(input 0 A )
				(param "x" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio -3.0) ) 30 ))
					
			(effect "Translate" ()
				(input 0 B )
				(param "x" (* render-aspect-ratio 3.0) (smoove 0.0 (* render-aspect-ratio 3.0) 1.0 0.0 ) 30 ))))

;;Spin by 180 * N degrees			
(define slide-tx2
	(fn (start stop inputs)
		(let (;(loud (loudness (* (+ start stop) 0.5)))
			  (loudness-lookup (step-tc 0.0 1
										0.3 2
										0.6 3
										0.9 4))
			  (n1 (loudness-lookup (loudness start)))
			  (n2 (loudness-lookup (loudness stop))))
		(apply	(layers (A B)
			(effect-stack
				(effect "Translate" (A)
					(param "x" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio -2.6))))
				(effect "Rotate" ()
						(input 0 A)
						(param "degrees" 0.0 (smoove 0.0 0.0 1.0 (* n1 180.0) ))
						(param "ey"  1.0)))			
			(effect-stack
				(effect "Translate" (B)
					(param "x" (* render-aspect-ratio 2.6) (smoove 0.0 (* render-aspect-ratio 2.6) 1.0 0.0 )))
				(effect "Rotate" ()
						(input 0 B)
						(param "degrees" (* n2 -180.0) (smoove 0.0 (* n2 -180.0) 1.0 0.0 ))
						(param "ey"  1.0))))
				(start stop inputs)))))
						
;;Curve					
(define slide-tx3
			(layers (A B)			
				(effect "Translate" ()
					(input 0 A)
					(param "z" 0.0 (smoove 0.0 0.0 0.5 -1.0))
					(param "x" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio -3.0))))
				(effect "Translate" ()
					(input 0 B)
					(param "x" (* render-aspect-ratio 3.0) (smoove 0.0 (* render-aspect-ratio 3.0) 1.0 0.0))
					(param "z" -1.0 (smoove 0.2 -1.0 1.0 0.0)))))

;;Linear					
(define slide-tx4
			(layers (A B)			
				(effect "Translate" ()
					(input 0 A)
					(param "z" 0.0 (smoove 0.0 0.0 0.3 -0.2))
					(param "x" 0.0 (smoove 0.3 0.0 0.7 (* render-aspect-ratio -3.0))))
				(effect "Translate" ()
					(input 0 B)
					(param "x" (* render-aspect-ratio 3.0) (smoove 0.3 (* render-aspect-ratio 3.0) 0.7 0.0))
					(param "z" -0.2 (smoove 0.7 -0.2 1.0 0.0)))))
		
;;Rotate the picture
;;Translate A along x and y.		
(define slide-tx5 
			(layers (A B)
			(effect-stack
				(effect "Translate" (A)
					(param "x" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio -2.0)))
					(param "z" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio  1.0)))
					)
				(effect "Rotate" ()
						(input 0 A)
						(param "degrees" 0.0 (smoove 0.0 0.0 1.0 180.0 ))
						(param "ey"  1.0)))			
			(effect-stack
				(effect "Translate" (B)
					(param "x" (* render-aspect-ratio 2.6) (smoove 0.0 (* render-aspect-ratio 2.6) 1.0 0.0 )))
				(effect "Rotate" ()
						(input 0 B)
						(param "degrees" -180.0 (smoove 0.0 -180.0 1.0 0.0 ))
						(param "ey"  1.0)))))
						
						

					
(define muvee-transition (if (= MOTION 'All) 	(effect-selector (shuffled-sequence slide-tx1 slide-tx2 slide-tx3 slide-tx4 slide-tx5))
						 (if (= MOTION 'Simple) slide-tx1 
						 (if (= MOTION 'Spin)   slide-tx2
						 (if (= MOTION 'Curve)  slide-tx3
						 (if (= MOTION 'Linear) slide-tx4 ()))))))

;-----------------------------------------------------------
;   Title and credits

(define constant 4.3)

(define slide-tx-Title 
			(layers (A B)
			(effect "Translate" ()
				(input 0 A )
				(param "x" 0.0 (smoove 0.0 0.0 1.0 (* render-aspect-ratio (* -1.0 constant)) ) 30 ))
					
			(effect "Translate" ()
				(input 0 B )
				(param "x" (* render-aspect-ratio constant) (smoove 0.0 (* render-aspect-ratio constant) 1.0 0.0 ) 30 ))))


				
(define is4:3?
  (< (fabs (- render-aspect-ratio 4/3)) 0.1))

(define BACKGROUND_IMAGE
  (format (if is4:3? "4-3" "16-9") "_panel.png"))
   

(define FOREGROUND_FX ( effect-stack 	view-fx
										reflection-fx))

(title-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.10 0.10) (0.90 0.90))))

(credits-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.10 0.10) (0.90 0.90))))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  (beat->sec average-transition-duration-beats (tempo 0)))

(muvee-title-body-transition slide-tx-Title title/credits-tx-dur)

(muvee-body-credits-transition slide-tx-Title title/credits-tx-dur)
