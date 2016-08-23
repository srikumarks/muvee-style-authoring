;http://muvee-style-authoring.googlecode.com/svn/trunk/lib/anaglyph.scm
;muSE v2
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

; This file defines the effect generating function named "anaglyph".
; The generated effect takes its input scene and renders it with red-cyan 
; split which gives you a full 3D experience when you view the
; muvee with red-cyan 3D glasses (with red on the left and cyan on the right).
;
; You can (load (resource "3d.scm")) and use the 
; anaglyph function in your styles, if you have
; this file present in your style's resource folder.

; ------------------------------------------------------------------
; anaglyph is a function that when given the camera offset
; between the left and right views, yields an effect that renders
; its input scene using red-cyan masking. The resultant effect is
; best used as part of the effect-stack immediately underneath
; the "Perspective" specification in the muvee-global-effect. 
; This ensures that *all* elements of the scene are taken into
; account when presenting the 3D view.
;
; A typical value of offset is 0.2
; ------------------------------------------------------------------
(define (anaglyph offset)
   (layers (A)
	   ; The left channel is presented in red and 
	   ; is offset to the right by the given amount.
	   (effect-stack 
	    (effect "Translate" (B)
		    (param "x" offset))
	    (effect "ColorWriteMask" ()
		    (input 0 A)
		    (param "Red" 1)
		    (param "Green" 0)
		    (param "Blue" 0)
		    (param "Alpha" 1)))

	   ; The right channel is presented in cyan and is offset
           ; by the given amount to the left. Cyan is a direct
	   ; mixture of blue and green. Using red and cyan
	   ; nearly gives you the full RGB color spectrum.
	   (effect-stack 
	    (effect "Translate" (B)
		    (param "x" (- offset)))
	    (effect "ColorWriteMask" ()
		    (input 0 A)
		    (param "Red" 0)
		    (param "Green" 1)
		    (param "Blue" 1)
		    (param "Alpha" 1)))))
	  
