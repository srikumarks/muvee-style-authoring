#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{RGBtoYUV}

This effect allows us to manipulate the @link["http://en.wikipedia.org/wiki/YUV"]{YUV} components of each pixel. So what we do is convert each pixel from @link["http://en.wikipedia.org/wiki/RGB_color_model"]{RGB} (our default color mode) to @link["http://en.wikipedia.org/wiki/YUV"]{YUV}, then manipulate each pixel in that color space, and finally convert back to @link["http://en.wikipedia.org/wiki/RGB_color_model"]{RGB} to be displayed on the screen.

@effect-parameter-table[
                        [ProgramString n/a "n/a"  @list{This parameter *must* be set to RGBtoYUV}]
                        
                        [NumParams 0 @math{>= 0} @list{This value *must* be set to 2}]
                        
                        [r0 0.0 @math{[0.0, 1.0]} @list{r0 is the value that is added to the Y component}]
                        [g0 0.0 @math{[0.0, 1.0]} @list{g0 is the value that is added to the U component}]
                        [b0 0.0 @math{[0.0, 1.0]} @list{b0 is the value that is added to the V component}]
                        [r1 0.0 @math{[0.0, 1.0]} @list{r1 is the value that is multiplied to the Y component}]
                        [g1 0.0 @math{[0.0, 1.0]} @list{g1 is the value that is multiplied to the U component}]
                        [b1 0.0 @math{[0.0, 1.0]} @list{b1 is the value that is multiplied to the V component}]
                        ]

@input-and-imageop[(A) #t]

@bold{Important note:}
@scheme[r1], @scheme[g1] and @scheme[b1] are @scheme[zero] by default (that happens because @scheme[RGBtoYUV] is embedded within the @scheme[FragmentProgram] effect). We need to explicitly set all three of them to @scheme[1.0] even though we might not necessarily want to use them. The reason is simple: These values are *multiplied* with the @link["http://en.wikipedia.org/wiki/YUV"]{YUV} components. If we leave them as zero, we'll have a situation where our @link["http://en.wikipedia.org/wiki/YUV"]{YUV} components all end up being @scheme[zero] by simply instantiating the @scheme[RGBtoYUV] effect.


@section{Examples}

@subsection{A linear progression from greyscale to saturated}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   The awesome of awesome styles.")
(code:comment "   The user image start at greyscale and progressively becomes saturated.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-segment-effect (effect "FragmentProgram" (A)
					(param "ProgramString" RGBtoYUV)
					(param "NumParams" 2)
					(param "r1" 1.0)
                                        (code:comment "The value below is multiplied with the U component")
                                        (param "g1" 0.0 (linear 1.0	2.0))     
                                        (code:comment "The value below is multiplied with the V component")
					(param "b1" 0.0 (linear 1.0	2.0))))
]

The user image starts as a completely grayscale picture. As the segment progresses along, the @scheme[U] and the @scheme[V] components are linearly incremented from @scheme[0.0] to @scheme[2.0]. If you look at the @link["http://en.wikipedia.org/wiki/YUV"]{YUV} documentation, you'll notice that if we set the @scheme[U] and @scheme[V] components to @scheme[0.0], this is equal to a greyscale conversion and if we increase the @scheme[U] and @scheme[V] component to twice or more their original value, it is equal to a saturation conversion of the image. This is exactly what this style does. The image below represents the final output for one segment, i.e. the saturated version of the image.

@image["image/rgbToYUV.jpg"]





