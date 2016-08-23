#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{ColorQuad}
Generates a colored rectangle. It is useful as a building block in other compositions such as creating a colored border around an image. This effect takes no inputs - i.e. it can be used directly as a layer in a @seclink["layers"]{layers} expression.

@effect-parameter-table[
[HexColor 1.0 @math{0xFFFFFFFF} @list{The hex value of the color of the rectangle. Either use the @scheme{HexColor} parameter or the @scheme[{a, r, g, b}] parameters.}]
[a 1.0 @math{(0.0 - 1.0)} @list{The alpha, or transparency value, of the color.}]
[r 1.0 @math{(0.0 - 1.0)} @list{The red component of the color.}]
[g 1.0 @math{(0.0 - 1.0)} @list{The green component of the color.}]
[b 1.0 @math{(0.0 - 1.0)} @list{The blue component of the color.}]
]


@input-and-imageop[() "No"]

@section{Simple color border around an image}

The muvee style creates a color border around the user image. See the screen shot for reference.


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My \"Lord I'm a genius\" style")
(code:comment "   This style creates a purple border around the user image")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))
                (effect "Translate" (A)
                        (param "z" -1.0))))

(define muvee-segment-effect
  (layers (A) 
          (effect-stack (effect "Scale" (A)
                                (param "x" 1.05)
                                (param "y" 1.05))
                        (effect "ColorQuad" ()	
                                (param "a" 1.0)
                                (param "r" 0.8)
                                (param "g" 0.8)
                                (param "b" 1.0)))
          A))


]

This style does four main things. They are:
@itemize{
 @item{Move all the user media backwards by @scheme[-1.0] in the z-space. (done as a @seclink["The_global_effect"]{global effect} )}
 @item{Creates a Color Surface using the @scheme[ColorQuad] effect.}
 @item{Scales that @scheme[ColorQuad] to @scheme[1.05] its original length. This is done so that the @scheme[ColorQuad] will be slightly bigger than the user media, giving you a color border.}
 @item{Draws the input media on top of the @scheme[ColorQuad]. (This is achieved by the letter @scheme[A] that is written just before we close the last two brackets in the segment effect code chunk.)}
             }

We have introduced the concept of  @seclink["layers"]{layers} in the example. Here's what happens, the @scheme[ColorQuad] effect does not take any input. But we want to display the user media in front of the @scheme[ColorQuad]; So we create a  @seclink["layers"]{layers} in which we have both input A ( which is the user picture ) and the @scheme[ColorQuad] effect. That results in the nice screen shot you see below.

You will notice the letter @scheme[A] all over the place. Generally it means an input data of some sort. But the input media it refers to is different depending on where it is placed. Here's the breakdown:

@itemize{
 @item{@scheme[(layers (A) .... )] Here @scheme[A] refers to the user media.}
 @item{@scheme[A] The very last @scheme[A] you see at the bottom of the segment effect also refers to the user media.}
 @item{@scheme["Scale" (A) ....] Here @scheme[A] refers to the @scheme[ColorQuad]. Consider the effect-stack as a chunk on its own. You first have a @scheme[ColorQuad]. And then the @secref["Scale"] effect is applied to that particular @scheme[ColorQuad].}
}
@image["image/colorQuad.jpg"]
