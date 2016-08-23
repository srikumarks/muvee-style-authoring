#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Desaturate}

Applies a fixed de-saturation operation on the colors of the images in its input. This effect is provided as a shader named @scheme[ColorMode_Desaturated] for use with the general @secref["FragmentProgram"] effect.

@effect-parameter-table[
                        [GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}.}]
                        ]

@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]

@section{Desaturation example}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   The style desaturates the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "FragmentProgram" (A) 
                        (param "ProgramString" ColorMode_Desaturated ))))

]

@image["image/desaturate.jpg"]