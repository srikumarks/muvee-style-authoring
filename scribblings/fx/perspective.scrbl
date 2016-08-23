#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Perspective}

Sets up the mapping from the 3D world to the view point of the camera, where objects that are farther away appear smaller. 

This effect is usually declared as a @seclink["The_global_effect"]{muvee-global-effect}. If you don't use Perspective as a global effect, the visible size of an object will be a constant - independent of its distance from the camera. (Such a projection is called ``orthographic projection''.)

@effect-parameter-table[
[fovy  45.0 @math{[0.0, 90.0)} @list{The field of view, expressed in degrees. Conceptually, it means how wide do we want our camera lens to be.}]
[zNear 0.1 @math{> 0.0} @list{This and the next parameter define z clipping planes. Objects closer to the camera than zNear are clipped and so are objects farther from the camera than zFar.}]
[zFar  10.0 @math{> 0.0} @list{zFar is conceptually the back of our clipping box.}]
]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Behaviour as an image is moved along the z-axis in Perspective Mode}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   This style uses the Perspective effect and demonstrate")
(code:comment "   what happens when we move our image further back in the z-axis.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))

(define muvee-segment-effect (effect "Translate" (A) 
				     (param "z" 0.0 (linear 1.0 -5.0))))

]

Our main focus is the @seclink["The_global_effect"]{muvee-global-effect}. That's where the @scheme[Perspective] effect has been declared. Now, what we're doing in the @seclink["The_segment_effect"]{segment-level-effect} is simply move the user image further in the z-axis as the segment duration progresses along. To fully appreciate the meaning of perspective, run the above style once; Then run it again after deleting the line @scheme[(effect "Perspective" (A))].

Do note that many styles declare @secref["CropMedia"] and @scheme["Perspective"] as Global Effects. This is a rather standard procedure and you are encouraged to do the same.

@image["image/scale_anim_xy.jpg"]