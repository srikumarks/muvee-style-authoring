#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Scale}

Scales the scene by the given x, y and z factors. For uniform scaling, the three factors have to have the same value. Negative scale values imply reflection. Note that if an even number of dimensions have -ve scale values, then the resultant scene's handedness (i.e. right-handed or left-handed) won't be changed.

@effect-parameter-table[
[x 0.0 "n/a" @list{Scales the width of the user media.}]
[y 0.0 "n/a" @list{Scales the height of the user media.}]
[z 0.0 "n/a" @list{Scales the depth of the user media.}]
]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Modifying the size and orientation of the input media}

The simple muvee style below scales every picture or video by @scheme[0.5] along the z-axis and by @scheme[-0.5] along the x-axis.

@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))
				(effect "Scale" (A)	
					(param "x" 0.5)
					(param "y" -0.5))))

]

This style reduces the user media to half its original size. Since the @scheme[y] parameter is negative, the image is also vertically inverted.

@image["image/scale_xy.jpg"]

@subsection{A simple animated scale along the x and y axis}

@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)


(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))

								
(define muvee-segment-effect (effect "Scale" (A)
					(param "x" 1.0 (linear 1.0 0.0)
					(param "y" 1.0 (linear 1.0 0.0)))))
]

At the start of each segment, the user image has its full width and height. However as the segment time progress from @scheme[0.0] to @scheme[1.0], the image is gradually scaled. Hence for each segment, the size of the image will gradually diminish until it is invisible. Refer to @secref["explicit-animation-curves"] for more info.

@image["image/scale_anim_xy.jpg"]