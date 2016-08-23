;muSE v2.0
;
; S10000_ImageSearch
;
; Turns captions on photos into images using google image search.
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

(style-parameters)

(segment-durations 8.0)

; Load the google search api module.
; See http://muvee-style-authoring.googlecode.com/svn/trunk/lib/google.scm
(load (resource "google.scm"))
	  
; Constructs an effect that overlays the given
; image on its input.
(define (overlay file)
  (layers (A)
	  A
	  (effect-stack
	   (effect "Translate" (A)
		   (param "x" (* render-aspect-ratio 0.7))
		   (param "y" -0.7))
	   (effect "Scale" (A)
		   (param "x" 0.25)
		   (param "y" 0.25))
	   (effect "PictureQuad" ()
		   (param "OnDemand" 1)
		   (param "Path" file)))))
   
(define muvee-segment-effect
  (fn (start stop (A))
      (case (list (source-type) (source-captions))
	(('image ((_ _ caption . _)))   
					; We have an image with some caption text.
					; Search for an image based on the caption text
					; and overlay it on the input.
					;
					; Note: We don't handle the "no images" case here.
	 ((overlay (google.fetch-result (google.search 'images caption 0) 0)) start stop (list A)))
	(_ A))))
	       

