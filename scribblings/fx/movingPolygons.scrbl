#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{MovingPolygons}

A custom effect used in the Reflections style. It renders random animating shapes on a plane. Refer to the screen shot below.

@section{Parameters}
 
@effect-parameter-table[       
                        
[PolygonType 0 @math{{0,1,2,3}}
             @list{@itemize{
                            @item{ @scheme[0]: Circle shape}
                            @item{ @scheme[1]: Square shape}
                            @item{ @scheme[2]: Double-triangle shape}
                            @item{ @scheme[3]: Star shape}}}]

[PolygonNum 10 @math{> 0} @list{The total number of polygons at any given type}]

[PolygonLength 0.1 @math{> 0.0} @list{The length of the polygon. For circles, it means radius. For squares and stars, it means the length of one side. This value is normalized with respect to the width of the screen}]

[PolygonRed 1.0 @math{[0.0,1.0]} @list{The value of the red component of our shape.}]

[PolygonGreen 1.0 @math{[0.0,1.0]} @list{The value of the blue component of our shape.}]

[PolygonBlue 1.0 @math{[0.0,1.0]} @list{The value of the green component of our shape.}]

[Accelerator 1.0 @math{> 0.0} @list{A constant that is multiplied to the speed of our polygon.}]

[Transparency 0.5 @math{[0.0,1.0]} @list{The transparency of our shapes}]
                        
]

@input-and-imageop[(A) #f]


@section{Examples}

@subsection{MovingPolygons example}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My not-so-awesome style.")
(code:comment "   This style adds moving shapes at the base of our picture")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Translate" (A)
                        (param "z" -1.0))))

(define muvee-segment-effect (layers (A)
                                     A
                                     (effect "MovingPolygons" ())))
]

@image["image/movingPolygons.jpg"]