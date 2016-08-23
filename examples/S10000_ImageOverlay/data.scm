;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S10000_ImageOverlay
;
;   Shows how to load a graphic and display it atop user media.
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

(style-parameters)

(segment-durations 2.0)


; The spider.png graphic is present in the style's
; folder. The (resource "spider.png") expression
; takes a path relative to the style's folder and
; expands it to the full path to the file, which
; we pass to the "PictureQuad" effect.
(define spider
  (effect "PictureQuad" ()
	  (param "Path" (resource "spider.png"))))

; The spider graphic defined above is a layer - i.e.
; it shows only the spider graphic and not the user media.
; Therefore we have to compose the final scene as 
; the user media on top of which the spider layer
; should be shown. We can easily express this composition
; using "layers" as shown below.
(define muvee-global-effect
  (layers (A)            ;; Input to the global effect is the user media.
	  A              ;; Show user media.
	  spider))       ;; Show spider graphic on top.
