#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Reflect}
Simulates the reflection of the input scene on a virtual floor. The reflection starts at full opacity and gradually moves to full transparency along the length of the floor.

@section{Parameters}

Here's how it works. We need to draw a floor on which we can reflect things. To do this we need the following:
@itemize{
         @item{ A random point (x,y,z coordinate) on the floor}
         @item{ A normal vector (x,y,z vector) that is perpendicular to the floor. It's basically a vector that sticks out of the floor}
         @item{ The left and right boundary of the floor (the x coordinate)}
         @item{ The front and back boundary of the floor (the z coordinate)}
        }

@effect-parameter-table[
[normalX  0.0 "n/a"  @list{The x coordinate of the normal vector}]
[normalY  1.0 "n/a"  @list{The y coordinate of the normal vector}]
[normalZ  0.0 "n/a"  @list{The z coordinate of the normal vector}]

[pointX   0.0 "n/a"  @list{The x coordinate of a random point on our floor}]
[pointY  -1.0 "n/a"  @list{The y coordinate of a random point on our floor}]
[pointZ   0.0 "n/a"  @list{The z coordinate of a random point on our floor}]

[nearX   -1.0 "n/a"  @list{The x coordinate of our left boundary. The floor stops at the boundary of x = -1.0 (default value)}]

[farX    1.0 "n/a"  @list{The x coordinate of our right boundary. The floor stops at the boundary of x =  1.0 (default value)}]                        

[nearZ   1.0 "n/a"  @list{The z coordinate of our front boundary. The floor stops at the boundary of z = 1.0 (default value)}]                        

[farZ    0.0 "n/a"  @list{The x coordinate of our left boundary. The floor stops at the boundary of z = 0.0 (default value)}]                        
                        
]

@input-and-imageop[(A) #f]

From the default values of reflect, we have a floor that has  the 4 coordinates:
@itemize{
         @item{@math{(-1.0, -1.0, 1.0)} Front Left}
         @item{@math{( 1.0, -1.0, 1.0)} Front Right}
         @item{@math{( 1.0, -1.0, 0.0)} Back Right}
         @item{@math{(-1.0, -1.0, 0.0)} Back Left}
         }             


@section{Examples}

@subsection{Image reflection example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   The style creates a partial reflection of the user media on the floor.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
                             (effect "CropMedia" (A))
                             (effect "Perspective" (A))
                             (effect "Translate" (A)
                                     (param "z" -1.0))))


(define muvee-segment-effect (effect "Reflect" (A)))

]


In the above muse style, we do a @secref["Translate"] of @scheme[-1.0] in the z-axis as a @seclink["The_global_effect"]{global effect} so that we can actually see the floor. Else what will happen is that the picture will take the full screen space and we won't enjoy the effect. At the @seclink["The_segment_effect"]{segment-level-effect}, we simply instantiate the @scheme["Reflect"] effect and use its default values.


@image["image/reflect.jpg"]