;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00524_Basic6
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

(style-parameters
   (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
   (one-of-few		TRANSITIONS		Dissolves	(Dissolves Fades ))
   (one-of-many		FILM_COLOR	BW	(BW Desaturated Color Saturated Sepia))
   (color			BORDER_COLOR 		0xFFFFFF)
   (color			BACKGROUND_COLOR 	0x000000))

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
  (+ (* base-duration-beats 9.0) 0.99))

(preferred-transition-duration average-transition-duration-beats)

(min-segment-duration-for-transition 0.0)

(transition-duration-tc 0.00 1.00
                        1.00 1.00)
					

(define view-fx
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A))
	(effect "Translate" (A)
			(param "z" -0.4))))

(define muvee-global-effect view-fx)

(define (float= x y err) 
  (and (> x (- y err)) (< x (+ y err))))

(define crop-aspect-ratio
  (fn args
    (cond
      ; non-magicSpotted image
      ((= (first (source-rectangles)) 'auto)
       (source-aspect-ratio))
      ; magicSpotted image
      ((= (first (source-rectangles)) 'manual)
       render-aspect-ratio)
      ; wide input video, narrow output frame
      ; (e.g. 16:9 input, 4:3 output)
      ((>= (source-aspect-ratio) (+ render-aspect-ratio 0.001))
       render-aspect-ratio)
      ; narrow input video, wide output frame
      ; (e.g. 4:3 input, 16:9 output)
      (_  (source-aspect-ratio)))))

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
      ('video (if (< factor 1.0)
                ; if source video is narrower than output frame
                ; (e.g. 4:3 input, 16:9 output), just scale x
                (cons factor 1.0)
                ; otherwise, no scaling is required
                (cons 1.0 1.0)))
      (_ (cons 1.0 1.0)))))
	  
	  
(define border+shadow
  (format (if (float= render-aspect-ratio 4/3 0.001) "4-3" "16-9")
          "_border.png"))

(define direction (looping-sequence 5.0 -5.0 ))		  

(define saturated (effect "FragmentProgram" (A)
						  (param "ProgramString" ColorMode_Saturated )))

(define desaturated (effect "FragmentProgram" (A)
						  (param "ProgramString" ColorMode_Desaturated )))
						  
(define page-contents-fx
  (fn ( (x y) (r s) b)
    (layers (A)
	
	   ; background
	  (effect-stack
	  (effect "Scale" (A)
			  (param "x" 2.01 )
			  (param "y" 2.01 ))
	  (effect "Alpha" (A)
				(param "Alpha" 1.0))
	  (effect "ColorQuad" ()
				(param "hexColor" BACKGROUND_COLOR)))

      ; foreground
      (effect-stack
	  
	    ;Color Effects
		(if (= FILM_COLOR 'BW) (effect "Greyscale" (A)) 
		(if (= FILM_COLOR 'Sepia) (effect "Sepia" (A)) 
		(if (= FILM_COLOR 'Desaturated) desaturated
		(if (= FILM_COLOR 'Saturated) saturated
		blank))))
		
		
        ; positioning
		 (effect "Scale" (A)
                (param "x" s)
                (param "y" s))
				
				
        (effect "Rotate" (A)
                (param "ex" 0.0)
                (param "ey" 0.0)
                (param "ez" 1.0)
                (param "degrees" r (linear 1.0 (+ r (direction)))))
        ; content
        (layers ()
		  ; border 
          (let ((screen-aspect-ratio (crop-aspect-ratio))
                (factor (/ screen-aspect-ratio render-aspect-ratio))
                ((x . y) (xy-stretch-fit-to-source factor))
                ; make constant-width border regardless of:
                ; - content's edge (left, right, top, bottom)
                ; - source aspect ratio (2:3, 1:1, 3:2, 10:1, ...)
                ; - render aspect ratio (4:3 or 16:9)
                (b+ (if (> factor 1.0) (* b factor) b))
                (x+ (* x (+ 1.0 (/ b+ screen-aspect-ratio))))
                (y+ (* y (+ 1.0 b+))))
            (effect-stack
              (effect "Translate" (A)
                      (param "z" 0.005))
              (effect "Alpha" (A)
                      (param "Alpha" 1.0))
              (effect "Scale" (A)
                      (param "x" x+)
                      (param "y" y+))
			(effect "ColorQuad" ()
				(param "hexColor" BORDER_COLOR))))
		
          ; user's media
          (effect-stack
            (effect "Alpha" (A)
                    (param "Alpha" 1.0))
            (effect "Translate" ()
                    (input 0 A)
                    (param "z" 0.010)))
			
          ; user's captions
          (effect-stack
            (effect "Alpha" (A)
                    (param "Alpha" 1.0))
            (effect "Translate" (A)
                    (param "z" 0.020))
            muvee-segment-captions))))))

	
(define page
  (fn args
    (let ((angle    (rand -3.00 3.00))
          (scale    (rand  0.80 0.96))
          (x-offset (rand -0.06 0.06))
          (y-offset (rand -0.04 0.04)))
      (page-contents-fx (x-offset y-offset)
                        (angle scale)
                        0.06))))

						
(define muvee-segment-effect  (effect-selector page))		

;;Title and Credits
(title-section
  (background
    (color BACKGROUND_COLOR))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.10 0.10) (0.90 0.90))))

(credits-section
  (background
    (color BACKGROUND_COLOR))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (font "-24,0,0,0,400,1,0,0,0,3,2,1,34,Arial")
    (layout (0.10 0.10) (0.90 0.90))))
						
								
(define dissolve-tx
  (effect "CrossFade" (A B)))

(define fade-to-background-tx
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
              (param "z" 0.03))
      (effect "Scale" (A)
              (param "x" 1.5)
              (param "y" 1.5))
      (effect "Alpha" (A)
              (param "Alpha" 0.0
                     (linear 0.5 1.0)
                     (linear 1.0 0.0)))
      (effect "ColorQuad" ()
              (param "hexColor" BACKGROUND_COLOR)))))


(define muvee-transition (if (= TRANSITIONS 'Dissolves) dissolve-tx fade-to-background-tx))

	 
(muvee-title-body-transition dissolve-tx 2.0)

(muvee-body-credits-transition dissolve-tx 2.0)