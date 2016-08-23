#lang scribble/doc
@(require scribble/manual "utils.ss")

@title{ShowTime - the muvee timeline}

@margin-note{This page needs a rewrite, but all the bits are there I think.}

@deftech{ShowTime} is our name for the timeline and rendering framework
that is responsible for previewing your muvees and for rendering them to
a file. @tech{ShowTime} uses the industry standard OpenGL graphics API to 
render the muvee. 

The basic unit of a ShowTime timeline is a @deftech{Show} which is,
broadly speaking, a function of time to a rendered frame. Every show
has an interval associated with it, outside of which it ceases to
influence the scene. A timeline is built by combining @tech{Shows}
to form compound Shows. For example, two Shows which display two 
different pictures can be combined with a @emph{Cut} operator to
create a Show that will display picture @scheme[A] before time @scheme[_t]
and picture @scheme[B] after time @scheme[_t].

A portion of the ShowTime framework is available for direct use by styles
so they can insert their own stock media into a muvee, such as a background
video. Here we describe the various functions that are available at the
lowest level of the effect framework and how to put them to great use.

@section{@scheme[video]}

@defproc[(video (path string) (aspect-ratio number) (mstart number) (speed number)) Show]{

@scheme[video] can be used to explicitly include style stock
video into the result timeline. It can be composed
using effects, layers, etc. just like any other source
video or photo clip.

A @scheme[(video ....)] expression
evaluates to a function that can be used like a zero-input
effect to place the video clip as a layer in the scene.
The portion of the video that will be used is determined
by the @scheme[_mstart] and @scheme[_speed] parameters. For example,
@schemeblock[
(define background (video (resource "background.wmv") 16/9 7.0 1/2))
]
will play the @filepath{background.wmv} video with 16/9 aspect ratio
starting from the 7.0 seconds at half speed. Since the function creates
a zero-input effect, the start and stop times aren't known yet. So
to insert this video into the timeline you instantiate the resultant effect
by providing the play interval, as follows -
@schemeblock[ 
(layers (A)
        (background start stop ())
        (code:comment "...other layers...")
        )
]

There is special support within the ShowTime muSE bindings for
using effect functions such as @scheme[background] that create Show objects 
and don't take any inputs - i.e. their @tech{input pattern} is @scheme[()].
In @scheme[(input N _xxx)] and @scheme[(layers ....)] expressions,
you can just use the function form without explicitly giving
the start and stop times. The start/stop times will
be automatically supplied from the context and the function will be 
evaluated to get a Show. For example, the above layers expression can
be written equivalently as -
@schemeblock[ 
(layers (A)
        background
        (code:comment "...other layers...")
        )
]
}

@section{@scheme[video-loop-track]}

@defproc[(video-loop-track (file string) (aspect-ratio number) 
                           (start number) (stop number) 
                           (mstart number) (mstop number)
                           (overlap number) (tx transition)
                           (trk track)) 
         track]{
A video clip can be looped for a specific period during a muvee.
This can be during a segment effect or as a background video
for the entire muvee. @scheme[video-loop-track] creates an instance
of such a loop.
 
The video's path, aspect ratio and duration have to be known
before-hand. For transitions between the clips, use the
parameters @scheme[_overlap] and @scheme[_tx], but ensure the transition
duration is less than half the video clip duration,
i.e.  @indent{@math{0 <= overlap} and @math{ overlap < (mstop - mstart)/2}}

To loop a 10-second 16:9-format @filepath{video.wmv} with a
2-second crossfade between them, use this:
@schemeblock[ 
(fn (start stop ())
    (video-loop-track (resource "video.wmv") 16/9
                      start stop 0.0 10.0
                      2.0 (effect "CrossFade" (A B))
                      ()))
]        
The initial value of trk should be @scheme[()]. At the end of the
recursion, trk contains all the objects needed to create
the looping video. You may then use this within the
layers expression.
}

@section{@scheme[with-inputs]}

@defproc[(with-inputs (inputs list-of-Shows) (fx effect)) layer]{
All the entries in a @scheme[(layers ....)] expression must be 
zero-input effects. Therefore it is a very frequent requirement
to take a specified effect and make it operate on the inputs of
the @scheme[layers] effect that's being constructed instead of
keeping its input pattern as free variables. You can use the
@scheme[with-inputs] function to supply the inputs for any effect
to turn it into a zero-input effect.

The @scheme[with-inputs] function evaluates to a zero-input effect 
(i.e. a @tech{layer}), binding the given inputs to the effect in the process. 
This function is very useful within @scheme[(layers ....)] expressions 
to make N-input effects operate on the layers' inputs.
}

@section{Lower level functions}

@subsection{@scheme[mes:video]}

@defproc[(mes:video (path string) (aspect-ratio number) (mstart number) (mstop number) (start number) (stop number)) Show]{
@New!{X}
Creates a video @emph{Show} that can be used as a layer in a composition. @scheme[_mstart] and @scheme[_mstop] give the media interval to show and @scheme[_start] and @scheme[_stop] give the playback interval. If the media interval given is smaller than the playback interval, you get slow motion video and if it is larger, you get fast motion video. If @scheme[_mstop] is a time before @scheme[_mstart], you get reversed video playback.
}       

@defproc[(mes:video (path string) (aspect-ratio number) (time-map list)) Show]{
@New!{X}
Similar to @scheme[mes:video] above, but provides for more flexible playback through the @scheme[_time-map] argument. The time-map is a list of piece-wise-linear playback intervals - i.e. of the form 
@schemeblock[
((start1 stop1 mstart1 mstop1) 
 (start2=stop1 stop2 mstart2 mstop2) 
 (start3=stop2 stop3 mstart3 mstop3) 
 ...)
] 
The playback intervals are expected to be increasing - i.e. the stop times @emph{must} occur after the start times, but the media interval can be discontinuous as well as do reverse video.
}

@subsection{@scheme[mes:image]}

@defproc[(mes:image (path string) (aspect-ratio number) (start number) (stop number)) Show]{
@New!{X}
Creates an image @emph{Show} that can be used as a layer in a composition.}

@defproc[(mes:image (path string) (aspect-ratio number) (start number) (stop number) 
                    (start-rectangle (tlx tly brx bry))  
                    (end-rectangle (tlx tly brx bry)) 
                    (num-clockwise-rotations integer)) Show]{
@New!{X}
Similar to above, but also specifies a "Ken Burns" animation rectangle pair
and the number of rotations to apply to the photo before presentation. The
rotation feature can be used to, for example, erect portrait photos which have
not been detected as such.}

@defproc[(mes:cached-image (path string) (size-indicator _)) string]{
@New!{X}
This creates, if necessary, a lower resolution version of the specified
image and returns the path to that image. The low resolution image is
cached in Reveal's cache and won't need to be re-generated if requested
again for the same image.

The @scheme[_size-indicator] can be one of -
@itemize{
         @item{@scheme[()] - meaning default cached image size, to a maximum of 2048x1024.}
         @item{@scheme[(width height)] - giving the desired maximum dimensions of the cached image.}
         @item{A number - then use the given number as the reduction factor for the image
                 size relative to the default.}
         }
}

@subsection{Working with image data during construction}

@defproc[(load-image (path-to-file string)) Image]{
@New!{X}
Loads and returns an object representing the pixels of an image
for use at construction time. You can use the @scheme[sample-image] function
described below to get at the pixels of the image.}

@defproc[(sample-image (image Image) (x number) (y number)) (a r g b)]{
@New!{X}
Gets a pixel from the given image located at the given relative x-y coordinate.
The x and y parameters are in the range 0 to 1 which map to the full width and height
of the image.}

@defproc[(select-points-using-image-weights (image Image) (N integer)) (list-of (x y))]{
@New!{X}
Given an image, treats it as a weight distribution and selects @scheme[N] points
from the image according to that distribution. The resulting points expressed in
normalized coordinates (i.e. 0 to 1 range) are returned as a list of @scheme[(x y)] values.}

