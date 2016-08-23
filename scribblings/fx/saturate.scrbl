#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Saturate}
Saturates the colors of the textures that it controls. Essentially the colors become more vivid. The level of saturation applied is fixed.

@section{Parameters}
 
@effect-parameter-table[
                        [GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}.}]
]

@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]

@section{Examples}

@subsection{Simple Saturation example}

This style saturates the colors of the user media. We use the generic @secref["FragmentProgram"] effect to create our saturation effect.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   The style saturates the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "FragmentProgram" (A) 
                        (param "ProgramString" ColorMode_Saturated ))))

]

@image["image/saturate.jpg"]