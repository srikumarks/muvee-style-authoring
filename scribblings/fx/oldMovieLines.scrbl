#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{OldMovieLines}
Simulates scratches on old film by rendering randomly animating lines on to the scene.

@section{Parameters}
 
@effect-parameter-table[
                        [NumLines  50 @math{> 0}  @list{The number of lines present at any give time}]
                        [Alpha  1.0 @math{[0.0,1.0]}  @list{The transparency of the lines}]
                        [Red    1.0 @math{[0.0,1.0]}  @list{The red component of the color of the lines}]
                        [Green  1.0 @math{[0.0,1.0]}  @list{The green component of the color of the lines}]
                        [Blue   1.0 @math{[0.0,1.0]}  @list{The blue component of the color of the lines}]
                        [LineGaps 100 @math{> 0} @list{The number of gaps in each individual line. This is what creates the empty spaces in the lines}]
                        [LineDuration 1.0 @math{> 0} @list{The duration measured in seconds of the lines}]
                        [LineDistance 0.2 @math{[0.0, 1.0]} @list{The total distance that the lines will cover during their lifespan. This value is normalized between 0.0 to 1.0. 0.0 means the lines don't move. 1.0 means the lines will cover the distance of the video width during its lifespan.}]
                        ]

@input-and-imageop[() #f]

@section{Examples}

@subsection{Old movie lines example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   This style adds vertical dotted lines on the input media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect
  (layers (A)
           A
          (effect "OldMovieLines" () 
                  (param "NumLines" 5)
                  (param "Red"   0.0)
                  (param "Blue"  0.0)
                  (param "Green" 0.0)
                  (param "Alpha" 0.5))))

]

Because this effect has no inputs, it has to be placed in a @secref["layers"].                                                                                                                                                                  

@image["image/oldMovieLines.jpg"]