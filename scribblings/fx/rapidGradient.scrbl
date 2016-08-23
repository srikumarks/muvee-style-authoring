#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{RapidGradient}

[[RapidGradient]] effect is a combination of [[GradientFade]] and [[RapidOverlay]]. The limitation with [[GradientFade]] is that the progress is monotonic. In other words, once a pixel has transitioned to the final output, it cannot go back to its original value. [[RapidGradient]] has no such limitation because a series of png files are used to describe to transition. Hexplode style uses RapidGradient extensively as a transition (amongst others). I would like to stress on one point: Use the [[GradientFade]] effect as much as possible. Only use [[RapidGradient]] when you find the former to be inadequate.

@effect-parameter-table[
[Path "" n/a @list{The folder in which the png files of the gradient resides}]
[FileType "png" n/a @list{The extension of the gradient image files.}]
[FlipMode 0 @math{{0,1,2,3,4}}
          @list{ @itemize{     @item{@scheme[0]: @scheme[FlipMode_None] - None.}
                               @item{@scheme[1]: @scheme[FlipMode_Horizontal] (i.e. mirror image.)}
                               @item{@scheme[2]: @scheme[FlipMode_Vertical] (i.e. upside down.)}
                               @item{@scheme[3]: @scheme[FlipMode_HorizontalAndVertical] (i.e. rotate 180 degrees.)}
                               @item{@scheme[4]: @scheme[FlipMode_Random] - Random flip per overlay.}}}]

[Quality 2 @math{{0,1,2,3}} @list{Sets the texture size of each overlay. The bigger the size, the more detailed the graphic, and the more resource hog it is. The range of values below sets the following texture sizes:
                                  @itemize{
                                      @item{@scheme[0: Quality_Lowest - 128 x 128]}
                                      @item{@scheme[1: Quality_Lower  - 256 x 256]}
                                      @item{@scheme[2: Quality_Normal - 512 x 512]}
                                      @item{@scheme[3: Quality_Higher - 1024 x 1024]}
                                      }}]

[RandomSeed 12345 "n/a" @list{Seed value to number generator for random and shuffled sequences.}]

[Sequence 0 @math{{0,1,2,3}} @list{Display order of overlays:
                                      @itemize{
                                               @item{@scheme[0]: @scheme[Sequence_Normal] - Plays each overlay in lexicographical order.}
                                               @item{@scheme[1]: @scheme[Sequence_Reversed] - Plays each overlay in reverse-lexicographical order.}
                                               @item{@scheme[2]: @scheme[Sequence_Shuffled] - Shuffles the ordering.}
                                               @item{@scheme[3]: @scheme[Sequence_Random] - Plays the overlays randomly.}}}]
]

@input-and-imageop[(A) "No"]

@section{Simple usage}

This is a simple usage of the RapidGradient effect.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome Style")
(code:comment "   This style creates a simple Rapid Gradient transition")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))
				
			
(define muvee-transition (effect "RapidGradient" (A)
                                 (param "Path" (resource "hex03"))))

]

@image["image/rapid_gradient.jpg"]