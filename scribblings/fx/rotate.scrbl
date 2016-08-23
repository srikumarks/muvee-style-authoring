#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Rotate}

Rotates the scene by a given angle about a given axis.

@effect-parameter-table[
[degrees 0.0 "n/a" @list{Amount of rotation in degrees.}]
[ex 0.0 @math{{-1,1}} @list{@scheme[ex], @scheme[ey] and @scheme[ez] specify the orientation of the axis about which to rotate the scene.}]
[ey 0.0 @math{{-1,1}} @list{}]
[ez 0.0 @math{{-1,1}} @list{}]
]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Rotation by 45 degrees along z-axis}

@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))



(define rotate45 
	(effect "Rotate" (A)
		(param "degrees" 45.0)
		(param "ez" 1.0)))
		

(define muvee-segment-effect rotate45)

]

We are interested in only the last two code chunks. We first define a variable named @scheme[rotate45]. @scheme[rotate45] will contain the @scheme[Rotate] effect and assign two of its parameters. The amount of @scheme[degrees] to rotate by is set at @scheme[45]. 
By setting the @scheme[ez] to @scheme[1.0], we indicate that we wish to rotate about the z-axis.

After we've done that, all we need to do is to assign the @scheme[rotate45] to @seclink["The_segment_effect"]{muvee-segment-effect}. Et voila!

@image["image/rotate45.jpg"]

@subsection{An animated rotation along the y-axis}


@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))
				(effect "Translate" (A)
					(param "z" -1.0))))



(define animate-rotate-45
	(effect "Rotate" (A)
		(param "degrees" 0.0 (linear 1.0 45.0))
		(param "ey" 1.0)))
		

(define muvee-segment-effect animate-rotate-45)
]

A few things to note here. 
@itemize{
 @item{At the @seclink["The_global_effect"]{global level}, I translated all the user media by @scheme[-1.0] in the z-axis. It's purely for aesthetic reasons as I want the rotation to be seen properly. }
 @item{I am now rotating along the y-axis and therefore @scheme[ey] has been set to 1.0}
 @item{The @scheme[degrees] parameter is being animated. At the start of each segment, the value of @scheme[degrees] is zero. At the end of the segment i.e. at time = @scheme[1.0] ( segment durations are normalized, meaning they start at t = 0.0 and end at t = 1.0 ) the value of @scheme[degrees] is @scheme[45.0]. So what we end up having is a smooth rotation throughout each segment. Refer to @secref["explicit-animation-curves"] for more info.}
}

If you find the explanation confusing, simply try the style out. You will quickly understand what the code is doing. 

@image["image/rotate45yaxis.jpg"]