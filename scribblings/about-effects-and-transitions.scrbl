#lang scribble/doc
@(require scribble/manual "utils.ss")

@title[#:style 'toc]{About effects and transitions}

@local-table-of-contents[]

@section{Introduction}

The structure of a muvee is very similar to the @italic{timeline} structure
provided by manual video editing software such as Apple's iMovie
and Microsoft Movie Maker. You can place clips in a timeline, apply
effects to these clips or to the whole video, add a sound track,
etc. and muvee Reveal's timeline structure can do all that.

There are some crucial differences though, the most important
being that many aspects of the composition such as determining the
durations of clips to put into the timeline happen automatically
in muvee Reveal. Also, the terms @italic{effects} and @italic{transitions} 
mean much more within a muvee style than it does in common manual video 
editors. We focus on the effect framework here.

In Windows Movie Maker, for example, you can apply an effect (say ``black and
white'') to a segment of video and it'll show up in black and white. It
affects no other segment. The effect also usually has no relationship
to, say, the music track. You have to tell it when to start and when to end.
The kind of effects that you can compose in a muvee style are far from being 
that rigid. muvee effects can respond to the music track, to the type of 
input material, come in a sequence, or go to any kind of customization 
that you as a style author care to get into. 

The key to this flexibility is the effect composition framework we
provide for style authors. The framework lets you combine @italic{primitive}
effects in a number of ways to achieve great variety.

@subsection{Terminology}

An @italic{effect} can be thought of as an instruction to modify its @italic{inputs}
in a specific way during a specific time interval of its
presentation. Here we usually use the term @italic{effect} to refer to both
the @italic{specification} of an effect as well as the @italic{instances} of the
specification. The distinction between an effect specification and an
effect instance will be highlighted where necessary. 

@include-section["primitive-effects.scrbl"]
@include-section["combining-effects.scrbl"]
@include-section["variable-effects.scrbl"]
@include-section["music-triggered-effects.scrbl"]

@section{Transitions}

A transition is technically a two-input effect where the time intervals of the two inputs overlap partially. There is no special notation for transitions in muSE. You use the same @scheme[(effect ....)] expression but provide as an @tech{input pattern} a list of two symbols. 

For example - @schemeblock[(effect "CrossFade" (A B))] is a transition.

The special variable @scheme[muvee-transition], when defined to a valid transition, serves as the specification of transitions from one segment to the next within a muvee. 

See also @secref["title-body-credits-transitions"].

@section{Segment information functions}
The following functions can be used in effect specifications to determine which part of the muvee the effect is being applied to.

@defproc[(segment-index) integer]{ 
The current segment index of an instance of @scheme[muvee-segment-effect] or a @scheme[muvee-transition]. In the case of the transition, this is the index of the section preceding the transition.}

@defproc[(segment-start-time (seg-index integer)) number]{ 
Gives you the start time of the segment specified by @scheme[_seg-index]. You can use this only within an instance of @scheme[muvee-segment-effect] or a @scheme[muvee-transition]. If you omit the @scheme[_seg-index], it gives the start time of the @emph{current} segment.}

@defproc[(segment-stop-time (seg-index integer)) number]{ 
Gives you the stop time of the segment specified by @scheme[_seg-index]. This is the counterpart of the @scheme[segment-start-time] function above.}

@defthing[muvee-last-segment-index integer]{
Evaluates to the index of the last segment of the muvee :-P This gives you (indirectly), the number of segments in the muvee.}

@section{Source information functions}
When specifying segment effects - i.e. effects that are to be applied to source clips - you can use these functions to determine the kind of source that the effect will be applied to and some of its properties. The most common use is probably to distinguish between portrait images, landscape images and video. 

All the source information functions take an optional segment index parameter. You may use the function @scheme[(#,(seclink "Segment_information_functions"(scheme segment-index)))] to get the ``current'' segment index. You may safely add/subtract 1 from this number to get the segment index for the neighbouring segment without generating any boundary warnings. For all the functions below, if the @scheme[_seg-index] parameter is omitted, then it is taken to mean ``index of current segment''.

@indent{@bold{Note}: These functions are only available for use within a segment level effect specification or within a transition.}

@defproc[(source-file-name (seg-index integer)) string]{ 
Evaluates to the full path to the file that the source clip refers to.}

@defproc[(source-type (seg-index integer)) symbol]{ 
Evaluates to @scheme['image], @scheme['video] or @scheme[()]}

@defproc[(source-is-image? (seg-index integer)) symbol-or-nil]{ 
Evaluates to @scheme['image] if the source is an image and to @scheme[()] otherwise.}

@defproc[(source-is-video? (seg-index integer)) symbol-or-nil]{ 
Evaluates to @scheme['video] if the source is a video clip and to @scheme[()] otherwise.}

@defproc[(source-is-intertitle? (seg-index integer)) symbol-or-nil]{
@New!{X} Evaluates to @scheme['intertitle] if the source is an intertitle card and to @scheme[()] otherwise.}

@defproc[(source-start-time (seg-index integer)) number]{ 
For video clips, evaluates to the mstart time.}

@defproc[(source-stop-time (seg-index integer)) number]{ 
For video clips, evaluates to the mstop time.}

@defproc[(source-duration (seg-index integer)) number]{ 
For video clips, evaluates to @math{mstop-mstart}.}

@defproc[(source-width (seg-index integer)) integer]{
For image clips, evaluates to the actual pixel width of the original image.}

@defproc[(source-height (seg-index integer)) integer]{ 
For image clips, evaluates to the actual pixel height of the original image.}

@defproc[(source-aspect-ratio (seg-index integer)) number]{
For image clips, evaluates to width/height.}

@defproc[(source-orientation (seg-index integer)) symbol]{
For image clips, evaluates to @scheme['portrait] or @scheme['landscape].}

@defproc[(source-rotation-deg (seg-index integer)) number-in-degrees]{ 
For image clips, evaluates to the user specified rotation value in degrees. This is a multiple fo 90 degrees.}

@defproc[(source-highlights (seg-index integer)) (list-of (cons _mstart _mstop))]{ 
Evaluates to a list of highlight intervals expressed as @scheme[(_mstart . _mstop)] pairs that overlap with the media interval of the current or given segment index. The list will be empty if the segment does not contain any highlights. The highlight intervals will all be clipped to the segment's own media interval.}

@defproc[(source-captions (seg-index integer)) (list-of (list _start _stop _caption-string))]{ 
This primitive gives the style author access to the caption text entered by the user and used within a muvee. Evaluates to a list of triplets @schemeblock[(start stop caption)] that tells the locations within the current or given segment where the user has added captions. Note that the interval is specified in @emph{play back time} and not in media time. For pictures, the interval will span the whole segment. For video clips, it can be a sub-interval of the whole segment.}

@defproc[(source-rectangles (seg-index integer)) (or (list 'auto ((_x1 _y1) (_x2 _y2))) 
                                                     (list 'manual ((_sx1 _sy1) (_sx2 _sy2)) ((_ex1 _ey1) (_ex2 _ey2))))]{ 
Returns any rectangles analyzed for the picture at the given segment index (or the current index) or those set by the user using magicSpot. If the segment isn't a picture, it results in @scheme[()]. The other values can be -
@schemeblock[('auto ((_x1 _y1) (_x2 _y2)))] Means the given rectangle is one that's automatically determined by the analyzer.
@schemeblock[('manual ((_sx1 _sy1) (_sx2 _sy2)) ((_ex1 _ey1) (_ex2 _ey2)))] Means the user has set manual pan/zoom rectangles. The start rectangle is given by the @math{[(sx1,sy1),(sx2,sy2)]} and the end rect is given by @math{[(ex1,ey1),(ex2,ey2)]}.}

@section{Render information}

@defthing[render-aspect-ratio number]{
Use this to customize style graphics and scene geometry according to the physical aspect ratio in which the muvee will be finally viewed. It can take on only two values as of March 2009 - either 16/9 or 4/3.}

@section{Unit helper functions}

@defthing[pi 3.141592654]{The world famous constant.}

@defproc[(deg->rad (degrees number)) number]{Converts @scheme[_degrees] into @emph{radian} units.}

@defproc[(rad->deg (radians number)) number]{Inverse of @scheme[deg->rad].}

@defproc[(beat->sec (beats number) (tempo-bpm number)) number]{
Converts a time interval expressed in beats into seconds, at the given tempo.}

@section{Getting into deep waters}
The other sections under @secref["About_effects_and_transitions"] describe how to use primitive
effects and combine them to create complex compositions. This section is about how the
@tech{effect combinators} work. We'll be stepping into the rabbit hole.

@margin-note{TODO: @tech{ShowTime} needs more documentation.}

To gain a full understanding of the innards of the @tech{effect combinators}, you need to 
understand some basics of @tech{ShowTime} and @tech{Shows}.

@subsection{What @italic{is} an effect?}

An @tech{effect} may be defined as an operator that works on a given set of input
@tech{Shows} over a time interval to produce a modified @tech{Show}. In conventional
editing literature, the term @emph{effect} is usually used to refer to one-input
effects and the term @deftech{transition} is used for two-input effects. For the purpose
of this section, we'll simply use the term @emph{effect} to mean either kind .. and in
fact include more kinds such as the zero-input effect which we otherwise refer to using
the term @tech{layer}.

We need to distinguish between @deftech{effect specifications} and @tech{effects}
in this section for it to make any sense.
@indent{@tech{Effects} are instances of @tech{effect specifications}. i.e. an effect
             specification when applied to a set of inputs over a specific time interval
             yields an effect as a @tech{Show}.}

We directly express the nature of effect specifications as muSE functions that have
a specific signature -
@schemeblock[
(fn (start stop inputs)
    (code:comment "Something that produces a Show.")
    ....    
    )
]

All the @emph{primitive} forms such as @scheme[(effect ....)] and @scheme[(layers ....)]
evaluate to effect specifications expressed as functions with the above signature. Having
gone through the @secref["Primitive_effects"] section, you might recall that a typical
primitive effect specification involves an @tech{input pattern}, for example -
@schemeblock[
(effect "Translate" (A) (code:comment "<- '(A)' is the input pattern.")
        ....)
]
The input pattern is directly used in the function that is generated by such an
expression, like so -
@schemeblock[
(fn (start stop (A))
    ....)
]

Therefore, the symbols @scheme[start], @scheme[stop] and @scheme[A] are automatically
made available in the body of the effect specification to compute any aspect of the effect.

@subsection{Rolling your own effects}

As of this writing, you cannot create your own @emph{primitive} effects. However, you
can write any function that has the above signature and evaluates to a @tech{Show} and use
it as an effect (almost) anywhere an effect is accepted.

For example, here is a ``blank'' effect that behaves as though it does nothing on its
input -
@schemeblock[
(define blank (fn (start stop (A)) 
                  A))
]
Since @scheme[A] is a @tech{Show}, @scheme[blank] indeed satisfies the effect signature
requirement and might be composed with other effects, say in an @scheme[effect-stack].

@subsection{The effect primitivity restriction}

@margin-note{The effect primitivity restriction might be removed in the future.}
There is only one restriction to keep in mind. When it comes 
to using an effect at the top level of a
@schemeblock[(define muvee-segment-effect ....)] 
or a 
@schemeblock[(define muvee-global-effect ....)] 
The effect @bold{must} be a @emph{primitive} effect. Though this seems to be an 
unacceptable restriction, it is easily satisfied by wrapping your custom effect 
in a @scheme[(layers ....)] form.

@subsection{Rolling your own effect combinators}

@tech{Effect combinators} are nothing but functions that create functions with the signature
that is expected of an effect. For example, here is an effect combinator that applies
effect @scheme[a] for the first half of its interval and @scheme[b] for the second half.
@schemeblock[
(define (two-part-effect a b)
  (fn (start stop (A))
      (let ((mid-point (math (start + stop) / 2)))
        (b mid-point stop (list (a start mid-point (list A)))))))
]

We'll leave the analysis of how that works as an exercise. A hint is to remember that
@scheme[a] and @scheme[b] are one-input effect specifications and to go back to the definition 
of an effect specification above to understand what you get when you apply them
to specific time intervals and inputs.

You need to be aware of the @secref["The_effect_primitivity_restriction"] when designing your own
effect combinators.

@section{A note on @deftech{Image Operators}}

@tech{Image operators} (a.k.a. @deftech{Image-Op}s) are a category of effects that cannot compose with each other. 

Some kinds of @emph{effects} such as @scheme["Alpha"], @scheme["Translate"], @scheme["Rotate"], etc. 
combine with the entire scene that they operate on. For example, if @scheme["Rotate"] is applied
to a scene composed of @tech{layers}, then each component layer will be rotated by the effect.

@margin-note{We do understand that this is quite a severe limitation for certain kinds of compositions
and are working to remove these restrictions.}

Some other effects such as @scheme["Mask"] and @scheme["Sepia"] cannot combine with
arbitrary effects unlike the others mentioned above. This is because they operate on 
the individual textures that compose the image and @tech{ShowTime} does not have support
for multi-pass rendering as of this writing (Dec 2008). We call these effects 
@tech{image operators} or @deftech{image-op}s for short. Image-ops are (or will ultimately
be) documented in the effect's manual page.
    

@section{Applications of effects}

@subsection{The segment effect}
This is an effect that is applied to each video and picture segment in
the muvee. You define the effect to use for each segment in the muvee by the
statement -
@schemeblock[
(define muvee-segment-effect _effect-expression)
]

@subsection{The global effect}
This is an effect that is used to treat the muvee as a whole. You
define the muvee's global effect using the statement -
@schemeblock[
(define muvee-global-effect _effect-expression)
]

@subsection{The transition}
The transition decides how to combine overlapping segments and present
them within the muvee. A transition is simply a two-input effect. You
define the muvee's transition using the statement -
@schemeblock[
(define muvee-transition _transition-expression)
]

@subsection[#:tag "title-body-credits-transitions"]{Title to Body and Body to Credits transitions}

@defproc[(muvee-title-body-transition (tx transition) (dur-secs number)) void]{
@scheme[_tx] is a normal transition function to use between the title and the body. The duration of the transition will be @scheme[_dur-secs]. The transition duration may be shortened depending on the duration of the title and the body.}

@defproc[(muvee-body-credits-transition (tx transition) (dur-secs number)) void]{
Similar to @scheme[muvee-title-body-transition] except that the transition specified applies between the body and the credits. The transition duration may be shortened depending on the duration of the title and the body.}

