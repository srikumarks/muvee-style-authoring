#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{GradientFade}
Progressively reveals its input image based on a given grey scale image called a @deftech{gradient map}. The image will be show in full at the beginning. It will progressively disappear starting from the dark regions of the gradient map and ending with the bright regions. At the end, the image will have completely disappeared.

@effect-parameter-table[
                        [Path n/a @list{n/a} @list{The full path of the gradient map}]
                        [Feather 10 @math{>0} @list{The blurriness of the boundary of the revealed portions of the image. Values more than @scheme[250.0] create pixel-sharp boundaries (along with jaggies). The default @scheme[10.0] results in a moderately soft edge. Use values >= @scheme[1.0].}]
                        [Reverse 0 @math{{0,1}} @list{When set to @scheme[1], Reverses the animation so that the input image will start off by being entirely invisible. It will start to show through the dark parts of the gradient map first followed by the brighter parts and will end up fully visible.}]
                        ]

@input-and-imageop[(A) "Yes."]


@section{A gradient fade between two pictures}

Though the @scheme[GradientFade] is written as a single input effect, we can use it as a transition by superimposing two gradient fades using @secref{layers}.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   A gradient fade example.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-transition (layers (A B)
  				(effect "GradientFade" ()
  					(input 0 B)
   					(param "Feather" 20.0 )
 					(param "Reverse" 1) (code:comment "Progressively reveal input B")
 					(param "Path" (resource "GradientMap.png")))
 				(effect-stack
 					(effect "Translate" (A)
 						(param "z" 0.003))
 					(effect "GradientFade" ()
 						(input 0 A)
 						(param "Feather" 20.0 )
 						(param "Reverse" 0) (code:comment "Progressively hide input A")
 						(param "Path" (resource "GradientMap.png"))))))

]

@image["image/GradientFade.jpg"]

The gradient map that was used is shown below.

@image["image/GradientMap.png"]




