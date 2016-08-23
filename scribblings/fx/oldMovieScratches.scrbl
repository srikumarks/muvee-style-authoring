#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{OldMovieScratches}

Simulates spot scratches on old film. Scratches appear as small ``wormy'' shapes that last for a single frame and appear more or less randomly across the screen. You can control the number of scratches and their color.

@section{Parameters}
 
@effect-parameter-table[
                        
[NumScratches  50 @math{> 0}  @list{The number of scratches present at any give time}]
[Alpha  1.0 @math{[0.0, 1.0]}  @list{The transparency of the lines}]
[Red    1.0 @math{[0.0, 1.0]}  @list{The red component of the color of the scratches}]                        
[Green  1.0 @math{[0.0, 1.0]}  @list{The green component of the color of the scratches}]
[Blue   1.0 @math{[0.0, 1.0]}  @list{The blue component of the color of the scratche}]

]

@input-and-imageop[() #f]

@section{Examples}

@subsection{Old movie scratches example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   The style adds scratches on the input media to give it an old movie feel.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect
  (layers (A)
           A
          (effect "OldMovieLines" () 
                  (param "NumScratches" 50)
                  (param "Red"   0.0)
                  (param "Blue"  0.0)
                  (param "Green" 0.0)
                  (param "Alpha" 0.5))))

]

Because this effect has no inputs, it has to be placed in a @secref["layers"].     

@image["image/oldMovieScratches.jpg"]