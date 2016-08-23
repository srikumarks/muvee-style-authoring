#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Translate}

Shifts the scene by the given amount in each of the three directions. Animating the parameters of the @scheme[Translate] effect is one of the most common ways to simulate physics in the scene.

@effect-parameter-table[
[x 0.0 "n/a" @list{Moves the scene in the x direction.}]
[y 0.0 "n/a" @list{Moves the scene in the y direction.}]
[z 0.0 "n/a" @list{Moves the scene in the z direction.}]
]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Translation along the x and z axis}

The muvee style below translates every picture or video by @scheme[-1.0] along the z-axis and by @scheme[-0.5] along the x-axis.

@schemeblock[ 
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It translates every user media by a fixed amount.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))
				(effect "Translate" (A)
					(param "x" -0.5)
					(param "z" -1.0))))

]

The @scheme["Translate"] effect has been set as a global effect. Setting the value of @scheme[z] to @scheme[-1.0], we are moving the picture into the screen. Setting the value @scheme[x] to @scheme[-0.5], we are moving the picture to the left of the screen.

@image["image/translate_xz.jpg"]


@subsection{An animated motion along the x-axis}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It moves the images across the screen from left to right.")
   
(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
										
(define muvee-segment-effect (effect "Translate" (A)	
                                     (param "x" -3.0 
                                            (code:comment "time  value pair")
                                            (linear 0.2    0.0)  
                                            (linear 0.8    0.0)
                                            (linear 1.0    3.0))))
]

The above example essentially creates a motion along the x-axis. At time = @scheme[0.0] to time = @scheme[0.2], the value of @scheme[x] smoothly increased from @scheme[-3.0] to @scheme[0.0]. At time interval @scheme[0.2] to @scheme[0.8], the value of @scheme[x] remains @scheme[0.0]. And finally at time interval @scheme[0.8] to @scheme[1.0], @scheme[x] increases from @scheme[0.0] to @scheme[3.0]. Refer to @secref["explicit-animation-curves"] for more info.

@image["image/translate_x.jpg"]