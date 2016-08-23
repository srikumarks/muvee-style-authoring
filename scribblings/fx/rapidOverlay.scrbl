#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{RapidOverlay}

Use @scheme[RapidOverlay] to bring an image sequence into your scene as a layer. You point the effect to a folder of images and they will be played like a movie in your scene. You can pick random images from the list or use them in sequence. PNG format is recommended for transparency support.
 
@effect-parameter-table[
[Path "" "n/a"
      @list{The path of the image overlays.}]
[FileType "png" "n/a" 
          @list{File extension of the overlays.}]
[FlipMode 0 @math{{0,1,2,3,4}}
          @list{ @itemize{     @item{@scheme[0]: @scheme[FlipMode_None] - None.}
                               @item{@scheme[1]: @scheme[FlipMode_Horizontal] (i.e. mirror image.)}
                               @item{@scheme[2]: @scheme[FlipMode_Vertical] (i.e. upside down.)}
                               @item{@scheme[3]: @scheme[FlipMode_HorizontalAndVertical] (i.e. rotate 180 degrees.)}
                               @item{@scheme[4]: @scheme[FlipMode_Random] - Random flip per overlay.}}}]

[FrameRate 0.0 @math{>= 0.0} 
           @list{Playback frame rate of overlay, in number of frames per second. This plays the set of overlays at the specified frame rate and in the order specified by the Sequence parameter, until the end of the effect is reached.

The default value of FrameRate is zero. This is a special case where it automatically calculates the required frame rate so that the sequence is time-stretched to fit the effect duration. However, this also means that the set of overlays will be played once and only once.}]

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

@input-and-imageop[() #f]

@section{Examples}

@subsection{A rapid series of heartshaped overlays on the user image.}

@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect 	(layers (A)
                                         A
                                         (effect "RapidOverlay" ()
                                                 (param "Path" (resource "overlay\\"))
                                                 (param "FrameRate" 10.0))))

]

This styles uses @secref["layers"] and an @secref["effect-stack"].

The three heart shaped images below are our overlays. What the above code does is to superimpose the images on the input media for every frame. 


@image["image/overlay1.png"]
@image["image/overlay2.png"]
@image["image/overlay3.png"]

The end result is the last three images below. The three heart shaped images are repeated throughout the muvee duration creating a nice effect.

@image["image/overlay1.jpg"]
@image["image/overlay2.jpg"]
@image["image/overlay3.jpg"]
