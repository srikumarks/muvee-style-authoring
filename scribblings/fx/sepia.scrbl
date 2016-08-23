#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Sepia}
Applies a sepia tone to the textures in the scene.

@section{Parameters}
 
@effect-parameter-table[ 

[SepiaMode 0 @math{{0,1}} 
           @list{
                 @itemize{
                          @item{@scheme[0]: The individual pixels are multiplied with a sepia matrix}
                          @item{@scheme[1]: The individual pixels are greyscaled first and then given a brownish tint}}}]                                                                 
                        
[GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}.}]

]

@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]

@section{Examples}

@subsection{Simple sepia-tone conversion}

This style converts the user media to a sepia-toned version.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It turns the user media to sepia.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Sepia" (A))))

]

@image["image/sepia.jpg"]