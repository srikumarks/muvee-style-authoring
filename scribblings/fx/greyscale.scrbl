#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Greyscale}
Converts an image from color to black and white (i.e. grey scale monochrome).

@effect-parameter-table[
                         [GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}.}]
                        ]

@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]


@section{Greyscale example}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It turns the user media to greyscale.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Greyscale" (A))))

]

@image["image/greyscale.jpg"]