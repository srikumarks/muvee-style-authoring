#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Alpha}

Controls the opacity of the scene it is applied to. The opacity of an object affected by more than one @scheme[Alpha] effect is determined by multiplying the opacity value specified by each of them.

@effect-parameter-table[
[Alpha 1.0 @math{[0.0 - 1.0]} @list{The new opacity value of the user media. A value of @scheme[0.0] means the scene is fully transparent. A value of @scheme[1.0] means the scene is fully opaque.}]
]

@input-and-imageop[(A) "No"]

@section{Simple usage}

The muvee style below halves the transparency of the user media.


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It halves the transparency of the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Alpha" (A)	
                        (param "alpha" 0.5))))

]

This style halves the transparency of the user media.

@image["image/alpha_half.jpg"]

@section{Animated alpha}

This example animates the transparency of an image to achieve a fade-to-black effect.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome Style")
(code:comment "   This style creates a simple fade to black behaviour")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))
				
			
(define muvee-segment-effect 
  (effect "Alpha" (A)
          (param "Alpha" 1.0 
                 (linear 0.5 0.0)
                 (linear 1.0 1.0))))

]


Refer to @secref["explicit-animation-curves"] for more info.