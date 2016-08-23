#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Flip}

A special transition that breaks up both input A and B and rotates them either about the x or y axis.

@effect-parameter-table[
                        
[Pattern 0 @math{{0,1,2}} 
         @list{@itemize{
                        @item{@scheme[0]: This coordinate set is made up of 6 rectangles on each face. It consists of 4 rectangles dividing the user media into 4 quadrants. And 2 rectangles at the center of sizes 0.5 and 0.33 repectively. The rectangles accelerate independently along the Z axis.}
                        @item{@scheme[1]: This coordinate set has a varying amount of rectangles of varying sizes all over the surfaces with varying accelerations. This pattern looks really nice with a lot of squares. A value of 1000 to 2000 will do the trick. A PolygonDistance of 5.0 is also suggested.}
                        @item{@scheme[2]: This is the pyramid pattern. Rectangles are created within the last created rectangle until we reach the center of the screen. This pattern looks good with a small amount of polygons.}}}]

[RotateAxis 0 @math{{0,1}} 
            @list{@scheme[0] means we rotate along the x-axis and @scheme[1] means we rotate along the y-axis. This parameter is incompatible with @scheme[Pattern] = @scheme[0]. }]

[NumPolygons 1000 @math{> 0} 
             @list{The number we want our input media to break up into. This parameter is incompatible with @scheme[Pattern] = @scheme[0]}]

[SurfaceColor 0xFFFFFFFF @math{ARGB32} 
              @list{The color tint of our main surface during the transition.}]

[PolygonColor 0xFFFFFFFF @math{ARGB32}
              @list{The color tint of the small squares during the transition.}]
              
[PolygonLength 0.1 @math{[0.0,1.0]} 
               @list{This is the length of our small squares with respect to the window size. This parameter is incompatible with @scheme[Pattern] = @scheme[0]}]

[PolygonDistance 1.0 @math{> 0}
                 @list{This is the distance we want our small squares to travel during a total progress of 1.0. This parameter is incompatible with @scheme[Pattern] = @scheme[0]}]

]
            
@input-and-imageop[(A) "Yes"]

@section{Examples}

@subsection{Default flip transition example.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My kick-butt style.")
(code:comment "This style showcases the flip transition.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-transition 
  (layers (A B)
          (effect "Flip" () 
                  (input 0 A )
                  (param "Input" 0 ))
          (effect "Flip" () 
                  (input 0 B )
                  (param "Input" 1 ))))
]

The flip transition breaks up both input A and input B into small squares. Input B is placed behind input A and they are rotated about the Y-axis. The screenshot below does a great disservice to this effect. Do run the style code above to fully appreciate the beauty of @scheme[flip].

@image["image/flip.jpg"]





