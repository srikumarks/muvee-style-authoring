#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{ReflectAndRipples}

Similar to the @secref{Reflect} effect, but adds water ripples on the ``floor''.

@section{Parameters}

@effect-parameter-table[
                        [floorA  0.5 @math{[0.0,1.0]}  @list{The transparency of the floor}]
                        [RippleFrequency  1.0  @math{>= 0.0}  @list{The number of water ripples per second.}]
                        [EnableRipples    1    @math{{0,1}}  @list{This parameter either enables or disables the ripples.}]          
                        [RippleHeight     0.05 @math{[0.0,1.0]}  @list{The initial height of the ripples}]
                        [RippleDuration   0.99 @math{[0.0,1.0]}  @list{The duration of each ripple. Note that a duration 1.0 means that the ripples *never* die and go on forever.}]  
                        [TopBackgroundColor 0xFFFFFF @math{RGB24} @list{The default background is white. This parameter allow you to change the top background color.}]
                        [BottomBackgroundColor 0xFFFFFF @math{RGB24} @list{The default background is white. This parameter allow you to change the bottom background color creating a nice gradient.}]
                        ]
         
@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Image reflection and ripples example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   The style creates a partial reflection of the user media with additional water ripples on the floor.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
                             (effect "CropMedia" (A))
                             (effect "Perspective" (A))
                             (effect "Translate" (A)
                                     (param "z" -1.0))))


(define muvee-segment-effect (effect "ReflectAndRipples" (A)
                                     (param "RippleFrequency" 500.0)
                                     (param "RippleDuration" 0.998)))

]

In the above muse style, we do a @secref["Translate"] of @scheme[-1.0] in the z-axis as a @seclink["The_global_effect"]{global effect} so that we can actually see the floor. Else what will happen is that the picture will take the full screen space and we won't enjoy the effect. At the @seclink["The_segment_effect)"]{segment-level-effect}, we instantiate the @scheme["ReflectAndRipples"] effect with a high @scheme[RippleFrequency] just to demonstrate the effect.

@image["image/reflectRipples.jpg"]