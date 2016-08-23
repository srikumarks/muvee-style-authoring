;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00523_Basic5
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.25	0.0  1.0)
  (continuous-slider	MUSIC_RESPONSE	0.5	0.0  1.0)
  (one-of-few		OVERLAY		Floral	(ArtDeco Floral Oriental SoftFocus None)))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED MUSIC_RESPONSE)


;-----------------------------------------------------------

(define (float= x y err) 
  (and (> x (- y err)) (< x (+ y err))))
  
(define overlay (if (= OVERLAY 'SoftFocus) 
					(if (float= render-aspect-ratio 4/3 0.001) "Overlays/SoftFocus-800x600.png" "Overlays/SoftFocus-960x540.png")				
				(if (= OVERLAY 'Floral)
					(if (float= render-aspect-ratio 4/3 0.001) "Overlays/Floral-800x600.png" "Overlays/Floral-960x540.png")
				(if (= OVERLAY 'Oriental)
					(if (float= render-aspect-ratio 4/3 0.001) "Overlays/Oriental-800x600.png" "Overlays/Oriental-960x540.png")
				(if (= OVERLAY 'ArtDeco)
					(if (float= render-aspect-ratio 4/3 0.001) "Overlays/ArtDeco-800x600.png" "Overlays/ArtDeco-960x540.png")
				())))))

(define view-fx
  (effect-stack
	(effect "CropMedia" (A))
    (effect "Perspective" (A))))

(define muvee-global-effect view-fx)	  		   

(define page-contents-fx  
   (layers (A)
			 
			(effect "Alpha" ()
					(input 0 A)
					(param "Alpha" 0.99)) 
			
			(if (= OVERLAY 'None)
			(fn args)
			(effect-stack
				(effect "Translate" (A)
						(param "z" 0.01))
				(effect "Alpha" (A)
						(param "Alpha" 0.8))
				(effect "PictureQuad" ()
						(param "Quality" Quality_Higher)
						(param "Path" (resource overlay)))))
								
			(effect-stack (effect "Translate" (A)
								  (param "z" 0.0002))
						  (effect "Alpha" (A)
								  (param "Alpha" 0.99))
						   muvee-segment-captions)))
						
(define muvee-segment-effect page-contents-fx)
				 
;;; transition selection ;;;
(define theme-path
  (fn (file)
    (format "Gradientmaps/" file )))

(define gradients1 (looping-sequence	"Gradientmaps/map1.png" "Gradientmaps/map11.png" 
										"Gradientmaps/map2.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map3.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map4.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map5.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map6.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map7.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map8.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map9.png" "Gradientmaps/map11.png" 
										"Gradientmaps/map10.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map11.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map12.png" "Gradientmaps/map12.png" ))
										
(define gradients2 (looping-sequence	"Gradientmaps/map1.png" "Gradientmaps/map11.png" 
										"Gradientmaps/map2.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map3.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map4.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map5.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map6.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map7.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map8.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map9.png" "Gradientmaps/map11.png" 
										"Gradientmaps/map10.png" "Gradientmaps/map12.png"  
										"Gradientmaps/map11.png" "Gradientmaps/map11.png"  
										"Gradientmaps/map12.png" "Gradientmaps/map12.png" ))
	
(define background-seq
  (let ((files (list-files (resource (theme-path "*.png")))))
    (apply shuffled-sequence
           (map theme-path files))))

	
(define gradientFade					
						(layers (A B)								
								(effect "GradientFade" ()
											(input 0 B)
											(param "Feather" 10.0 )
											(param "Reverse" 1)
											(param "Path" (resource (gradients1))))
								(effect-stack
									(effect "Translate" (A)
											(param "z" 0.003))
									(effect "GradientFade" ()
											(input 0 A)
											(param "Feather" 5.0 )
											(param "Reverse" 0)
											(param "Path" (resource (gradients2)))))))
											
														
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
					(linear 0.5 1.0)
					(linear 1.0 0.0))
              (param "r" 0.85)
              (param "g" 0.85)
              (param "b" 0.85)))))

														
											
		   
(define muvee-transition (effect-selector (looping-sequence gradientFade fade-to-white-tx)))


;;;Title and Credit section	
(define view-fx-TC
  (effect-stack
	(effect "CropMedia" (A))
    (effect "Perspective" (A))
	(if (= OVERLAY 'None)
	 blank
	(layers (A)		
			 A
			(effect-stack
				(effect "Translate" (A)
						(param "z" 0.01))
				(effect "Alpha" (A)
						(param "Alpha" 0.99))
				(effect "PictureQuad" ()
		                (param "Quality" Quality_Higher)
		                (param "Path" (resource overlay))))))))

			
(title-section
  (background
   (image "TitleCredit_BG.jpg"))
  (foreground (fx view-fx-TC))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-21,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
 (background
   (image "TitleCredit_BG.jpg"))
 (foreground (fx view-fx-TC))
 (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-21,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition fade-to-white-tx title/credits-tx-dur)

(muvee-body-credits-transition fade-to-white-tx title/credits-tx-dur)
