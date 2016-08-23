#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Blur}
Blurs images using a simple technique. The quality of the blur may not be suitable for some kinds of compositions. Its primary advantage is that it is fast.

@effect-parameter-table[
[Amount 0.0 @math{>= 0.0} @list{The amount of blur is given in a logarithmic scale. @scheme[0.0] results in no blur, @scheme[1.0] results in a 2x2 grid blur, @scheme[2.0] results in a 4x4 grid blur, and so on.}]
]

@input-and-imageop[(A) "No"]

@section{Simple image blur}

This style blurs the user media.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It blurs the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Blur" (A)
                        (param "Amount" 4.0))))

]

@image["image/blur_effect.jpg"]