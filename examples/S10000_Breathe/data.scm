;muSE v2.0
;
; Breathe style
;
; Copyright (c) 2006 muvee Technologies Pte Ltd.
; All rights reserved.

(style-parameters)

;;
;;Title and Credits
;;
(title-section
 (background (image "breathe1.jpg")) 						;The image we want to use
 (text
  (color 32 80 32)											;Text Color
  (font "-43,0,0,0,400,0,0,0,0,3,2,1,34,Fiolex Girls")		;Text font in LOGFONTA format
  (fade-out)))

(credits-section
 (background (image "breathe1.jpg"))
 (text
  (color 32 80 32)
  (font "-32,0,0,0,400,0,0,0,0,3,2,1,34,Fiolex Girls")
  (fade-in)))
  
;;; transitions between title/credits and body ;;;
(muvee-title-body-transition (effect "CrossFade" (A B)) 2.0)

(muvee-body-credits-transition (effect "CrossFade" (A B)) 2.0)

;;The average segment duration measured in beats
(segment-durations 4.0 8.0 8.0)

;;This transfer curve modifies the segment durations based on the loudness of the music
;;When we have soft music, the duration is 8 beats, And when we have loud music, the duration is 2.25 beats.
(segment-duration-tc 0.00 2.00
                     0.35 2.00
                     0.36 1.50
                     0.75 1.50
                     1.00 1.25)					 

;;The gradient maps we want to use during the trasition
(define gradientFiles	(looping-sequence 	"GradientMaps/gradient01.png"  "GradientMaps/gradient01.png"  
											"GradientMaps/gradient02.png"  "GradientMaps/gradient02.png" 
											"GradientMaps/gradient03.png"  "GradientMaps/gradient03.png"))
											
;;We will flip the gradient maps horizontally and vertically to create more variance
(define flipLoop (looping-sequence FlipMode_None FlipMode_Horizontal FlipMode_Vertical FlipMode_HorizontalAndVertical))

;;This is the GradientFade effect that is used as a transition.
;;Note that both inoutA and inputB are gradient-faded.
(define tx  (fn args
				(let ((flip (flipLoop)))
				(apply (layers (A B)								
	  				(effect "GradientFade" ()
	  					(input 0 B)
	   					(param "Feather" 5.0)
	 					(param "Reverse" 1)										;InputA is reverse gradientfaded. Meaning it starts at full transparency and slowly becomes opaque.
						(param "FlipMode" flip)									;We'll ocassionally flip the gradient map to create some variance.
	 					(param "Path" (resource (gradientFiles))))				;Here we feed in the gradient map paths
	 				(effect-stack
	 					(effect "Translate" (A)									;InputA is moved slightforward in the z-space to avoid the inputs from z-fighting with one another
	 						(param "z" 0.003))
	 					(effect "GradientFade" ()
	 						(input 0 A)
	 						(param "Feather" 5.0)							
	 						(param "Reverse" 0)									;InputA is forward gradientfaded. Meaning it starts at full opacitiy and slowly becomes transparent.
							(param "FlipMode" flip)
	 						(param "Path" (resource (gradientFiles))))))
							args))))

(define dissolve-tx (effect "CrossFade" (A B)))
			
;;We'll either do a simple dissolve transition or a gradientfade. 
;;Which one to choose from depends on the loudness of the music			
(define muvee-transition
	(select-effect/loudness 
			(step-tc 0.00 tx
                 	 0.35 dissolve-tx
				     0.75 tx 
				     1.00 dissolve-tx)))

;;The trasition duration transfer curve.
(transition-duration-tc 0.0 2.0
                        1.0 1.5)

(preferred-transition-duration 2.0)

(min-segment-duration-for-transition 2.0)
