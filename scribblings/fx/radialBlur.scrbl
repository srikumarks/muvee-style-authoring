#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{RadialBlur}

This effect creates a radial blur effect on the user content. It should be primarily used as a @seclink["Music_triggered_effects"]{flash} effect. A radial blur is achieved by superimposing the user image on itself repeatedly and slowly increasing the width and height. The final result looks like an inverted pyramid. The bottom most layer is the original image. We then end up with a radial blur.  

@effect-parameter-table[
                        [ScaleStep 0.001 @math{> 0.0} @list{From one level to the next, this parameter dictates by how much we will scale the next layer.}]
                        [TranslateStep 0.001 @math{> 0.0} @list{From one level to the next, this parameter dictates by how much we will space-out the next layer.}]
                        [AlphaStep 0.03 @math{> 0.0} @list{From one level to the next, this parameter dictates by how much we will decrease the alpha of the next layer.}]
                        [LODStep 0.01 @math{> 0.0} @list{From one level to the next, this parameter dictates by how much we will decrease the Level-Of-Detail (or sharpness) of the next layer.}]

                        ]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{A radial blur effect.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My mesmerisingly good style.")
(code:comment "   This style creates a radial blur.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-segment-effect (effect "RadialBlur" (A)))

]


@image["image/radialBlur.jpg"]





