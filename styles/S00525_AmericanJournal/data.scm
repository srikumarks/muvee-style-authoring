;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00525_AmericanJournal
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
  (color				BORDERCOLOR 0xFFFFFF ))
  

;-----------------------------------------------------------
;   Music pacing
;   - segment/transition durations and playback speed

(define base-duration-beats
  (- 1.0 AVERAGE_SPEED))

(define average-segment-duration-beats
  (+ (* base-duration-beats 18.0) 2.0))

(segment-durations average-segment-duration-beats)

(segment-duration-tc 0.00 1.00
                     1.00 1.00)

(time-warp-tc 0.00 0.50
              0.35 0.50
              1.00 1.00)

(define average-transition-duration-beats
  (+ (* base-duration-beats 4.0) 1.0))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        1.00 1.00)
						
						

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))))

(define muvee-global-effect view-fx)


(define (float= x y err) 
  (and (> x (- y err)) (< x (+ y err))))

(define theme-path
  (fn (file)
    (format "Backgrounds/" (if (float= render-aspect-ratio 4/3 0.001) "4-3/" "16-9/" ) file )))

	
(define background-seq
  (let ((files (list-files (resource (theme-path "*.jpg" )))))
    (apply looping-sequence
           (map theme-path files))))
		   
(define xy-stretch-fit-to-source
  (fn (factor)
    (case (source-type)
      ('image (if (> factor 1.0)
                ; if source is very long landscape image,
                ; inverse-scale y and maintain x,
                ; thus preserving aspect ratio
                (cons 1.0 (/ factor))
                ; for other types of images, just scale x
                (cons factor 1.0)))
      ('video (if (and (not (float= render-aspect-ratio 4/3 0.001))
                       (float= (source-aspect-ratio) 4/3 0.001))
                ; special case - 4:3 source video on non-4:3 output
                (cons factor 1.0)
                ; for other combination of source videos and
                ; output frame aspect ratios, no scaling needed
                (cons 1.0 1.0)))
      (_ (cons 1.0 1.0)))))
		  

(define page-contents-fx
  (fn (bkgnd (x y) (r s) b)
    (layers (A)
	
		; background
		(effect-stack
			(effect "Scale" (A)
				(param "x" 1.001 ))
			(effect "SeamlessBackground" ()
				(param "OnDemand" 1)
				(param "Quality" Quality_Higher)
				(param "Path" (resource bkgnd))))
				
	    ; foreground
	    (effect-stack
	        ; positioning
	        (effect "Translate" (A)
	                (param "x" x)
	                (param "y" y))
	        (effect "Rotate" (A)
	                (param "ex" 0.0)
	                (param "ey" 0.0)
	                (param "ez" 1.0)
	                (param "degrees" r))
	        (effect "Scale" (A)
	                (param "x" s)
	                (param "y" s))
        ; content
        (layers ()		
		
		
		  ;drop shadow
          ;(artwork is designed such that the border occupies
          ;exactly 90% of the frame size, and scaling it by a
          ;factor of 10/9 will fit it to the content's area)
          (let ((screen-aspect-ratio (if (= (first (source-rectangles)) 'manual)
                                       render-aspect-ratio
                                       (source-aspect-ratio)))
                (factor (/ screen-aspect-ratio render-aspect-ratio))
                ; make constant-width border regardless of:
                ; - content's edge (left, right, top, bottom)
                ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
                ; - render aspect ratio (4:3 or 16:9)
                ((x . y) (xy-stretch-fit-to-source factor))
                (b+ (if (> factor 1.0) (* b factor) b))
                (x+ (* x 1.1 (+ 1.0 (/ b+ screen-aspect-ratio))))
                (y+ (* y 1.1 (+ 1.0 b+))))
            (effect-stack
              (effect "Translate" (A)
                      (param "z" 0.005))
              (effect "Alpha" (A)
                      (param "Alpha" 1.0))
              (effect "Scale" (A)
                      (param "x" x+)
                      (param "y" y+))
					  
			  (effect "PictureQuad" ()
                      (param "Quality" Quality_Normal)
                      (param "Path" (resource (if (float= render-aspect-ratio 4/3 0.001) "4-3_border.png" "16-9_border.png"))))))
		
		
		  ; border 
          ; (artwork is designed such that the border occupies
          ; exactly 90% of the frame size, and scaling it by a
          ; factor of 10/9 will fit it to the content's area)
          (let ((screen-aspect-ratio (if (= (first (source-rectangles)) 'manual)
                                       render-aspect-ratio
                                       (source-aspect-ratio)))
                (factor (/ screen-aspect-ratio render-aspect-ratio))
                ; make constant-width border regardless of:
                ; - content's edge (left, right, top, bottom)
                ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
                ; - render aspect ratio (4:3 or 16:9)
                ((x . y) (xy-stretch-fit-to-source factor))
                (b+ (if (> factor 1.0) (* b factor) b))
                (x+ (* x 1.0 (+ 1.0 (/ b+ screen-aspect-ratio))))
                (y+ (* y 1.0 (+ 1.0 b+))))
            (effect-stack
              (effect "Translate" (A)
                      (param "z" 0.005))
              (effect "Alpha" (A)
                      (param "Alpha" 1.0))
              (effect "Scale" (A)
                      (param "x" x+)
                      (param "y" y+))
              (effect "ColorQuad" ()
                      (param "hexColor" BORDERCOLOR))))
		
          ; user's media
          (effect-stack
            (effect "Translate" ()
                    (input 0 A)
                    (param "z" 0.010)))					
				
          ; user's captions
          (effect-stack
            (effect "Alpha" (A)
                    (param "Alpha" 0.999))
            (effect "Translate" (A)
                    (param "z" 0.020))
            muvee-segment-captions))))))
		  
		  

(define page
  (fn args
    (let ((angle    (rand -3.00 3.00))
          (scale    (rand  0.70 0.76))
          (x-offset (rand -0.06 0.06))
          (y-offset (rand -0.04 0.04)))
      (page-contents-fx (background-seq)
                        (x-offset y-offset)
                        (angle scale)
                        0.06))))

						
(define muvee-segment-effect  (effect-selector page))

;;; push ;;;
(define push-tx
  (let (((axis . vec) (if (= DIRECTION 'Vert)
                        (cons "y" 2.0)
                        (cons "x" (* render-aspect-ratio -1.997))))
        (~vec (- vec)))
    (layers (A B)
      (effect "Translate" ()
              (input 0 A)
              (param axis 0.0
                     (bezier 1.0 vec 0.0 vec)))
      (effect "Translate" ()
              (input 0 B)
              (param axis ~vec
                     (bezier 1.0 0.0 ~vec 0.0))))))


					 
;;; transition selection ;;;

(define muvee-transition push-tx)
  
  
(define FOREGROUND_FX
   (layers (A)
	 (effect-stack
		(effect "Perspective" (A))
		(effect "Translate" (A)
			(param "x" 0.5 )
			(param "z" -0.001))		
		(effect "ColorQuad" ()))				
	 (layers ()
		(effect "Scale" ()
			(input 0 A)
			(param "x" 1.00 )))))		
		
(title-section
  (background
	(image (if (float= render-aspect-ratio 4/3 0.001) "4-3_TC.jpg" "16-9_TC.jpg" )))
  (foreground (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
 (background
   (image (if (float= render-aspect-ratio 4/3 0.001) "4-3_TC.jpg" "16-9_TC.jpg" )))
 ;(foreground (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-28,0,0,0,400,0,0,0,0,3,2,1,34,Times New Roman")
    (layout (0.05 0.05) (0.95 0.95))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))
	 
;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  (beat->sec average-transition-duration-beats (tempo 0)))

 
(muvee-title-body-transition push-tx title/credits-tx-dur)

(muvee-body-credits-transition (effect "CrossFade" (A B)) title/credits-tx-dur)

  
  

						