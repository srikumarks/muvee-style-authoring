#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{ColorMapRGB}

Maps the color of an image according to a piece-wise linear curve specified for each color component. For each color component, the curve has @emph{five} control points indexed as 0, 1, 2, 3 and 4. Each control point is given by an input color value and a corresponding output color value. The input values for a given component @bold{must} be in increasing order.


@effect-parameter-table[
                                   
[InRi n/a @math{(0.0 - 1.0)} @list{The input r@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[InGi n/a @math{(0.0 - 1.0)} @list{The input g@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[InBi n/a @math{(0.0 - 1.0)} @list{The input b@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[InAi n/a @math{(0.0 - 1.0)} @list{The input a@subscript{i}. {i = 0, 1, 2, 3, 4}}]

[OutRi n/a @math{(0.0 - 1.0)} @list{The output r@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[OutGi n/a @math{(0.0 - 1.0)} @list{The output g@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[OutBi n/a @math{(0.0 - 1.0)} @list{The output b@subscript{i}. {i = 0, 1, 2, 3, 4}}]
[OutAi n/a @math{(0.0 - 1.0)} @list{The output a@subscript{i}. {i = 0, 1, 2, 3, 4}}]

[GlobalMode  0 @math{[0,1]}  @list{@deftech{GlobalMode} can be set to @scheme[0] or @scheme[1].
                                   @itemize{
                                            @item{@scheme[0]: Set to @scheme[0] to use it as a segment-level effect. The effect becomes an @tech{Image-Op}.}
                                            @item{@scheme[1]: Set to @scheme[1] to use it as a global effect. In this case, the effect is not an @tech{Image-Op}.}}}]
]



@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]


@section{Remapping the golden color of an overlay to blue-green}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My insanely awesome style.")
(code:comment "   This style changes the default color of an overlay")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define ColormapEffect (effect "ColorMapRGB" (A)
                               (code:comment "Red Channel Transfer curve")
                               (param  "InR0" 0.00)
                               (param "OutR0" 0.00)
                               
                               (param  "InR1" 0.66)
                               (param "OutR1" 0.29)
                               
                               (param  "InR2" 0.72)
                               (param "OutR2" 0.29)
                               
                               (param  "InR3" 0.87)
                               (param "OutR3" 0.24)
                               
                               (param  "InR4" 1.00)
                               (param "OutR4" 1.00)	
                               
                               
                               (code:comment "Green Channel Transfer curve")                               
                               (param  "InG0" 0.00)
                               (param "OutG0" 0.00)
                               
                               (param  "InG1" 0.07)
                               (param "OutG1" 0.72)
                               
                               (param  "InG2" 0.20)
                               (param "OutG2" 0.72)
                               
                               (param  "InG3" 0.60)
                               (param "OutG3" 0.71)
                               
                               (param  "InG4" 1.00)
                               (param "OutG4" 1.00)	
                                
                               
                               (code:comment "Blue Channel Transfer curve")
                               (param  "InB0" 0.00)
                               (param "OutB0" 0.00)
                               
                               (param  "InB1" 0.38)
                               (param "OutB1" 0.82)
                               
                               (param  "InB2" 0.59)
                               (param "OutB2" 0.80)
                               
                               (param  "InB3" 0.87)
                               (param "OutB3" 0.75)
                               
                               (param  "InB4" 1.00)
                               (param "OutB4" 1.00)))								


 (define muvee-segment-effect (layers (A)
                                       A
                                      (effect-stack
                                       ColormapEffect
                                       (effect "PictureQuad" ()
                                               (param "Path" (resource "flowerPattern.png"))))))
]

In the above style, all the color channels are modified and all they all have @bold{5} control points. As you can see, every @bold{In{XY}} parameter has a corresponding @bold{Out{XY}} parameter. And every where inbetween our control points, we do a linear interpolation. 

@image["image/spacer.png"]


The first image you see below is the orignal overlay.

@image["image/ColorMapRGB1.jpg"]



@image["image/spacer.png"]



This second image however, has had it colors remapped by the @bold{ColorMapRGB} effect.


@image["image/ColorMapRGB2.jpg"]


@image["image/spacer.png"]


Ths Red channel graph below is a visual representation of the values we fed in the @bold{ColorMapRGB} effect. The brown dotted line is what an unaltered transfer curve would look like. Essentially, there would have been a one to one match between the input and the output. However we have modified the transfer curve to look like the purple line, thus changing the color of the original media.  We gave the red channel the following control points: @bold{ {0.0, 0.0} {0.66, 0.29} {0.72, 0.29} {0.87, 0.24} {1.0,1.0}}.

@image["image/ColorMapRGB_RedChannel.jpg"]


@image["image/spacer.png"]



Ths Green channel graph below is a visual representation of the values we fed in the @bold{ColorMapRGB} effect. The brown dotted line is what an unaltered transfer curve would look like. Essentially, there would have been a one to one match between the input and the output. However we have modified the transfer curve to look like the purple line, thus changing the color of the original media. We gave the green channel the following control points: @bold{ {0.0, 0.0} {0.07, 0.72} {0.20, 0.72} {0.60, 0.71} {1.0,1.0}}.

@image["image/ColorMapRGB_GreenChannel.jpg"]



@image["image/spacer.png"]



Ths Green channel graph below is a visual representation of the values we fed in the @bold{ColorMapRGB} effect. The brown dotted line is what an unaltered transfer curve would look like. Essentially, there would have been a one to one match between the input and the output. However we have modified the transfer curve to look like the purple line, thus changing the color of the original media. We gave the green channel the following control points: @bold{ {0.0, 0.0} {0.38, 0.82} {0.59, 0.80} {0.87, 0.75} {1.0,1.0}}.

@image["image/ColorMapRGB_BlueChannel.jpg"]

