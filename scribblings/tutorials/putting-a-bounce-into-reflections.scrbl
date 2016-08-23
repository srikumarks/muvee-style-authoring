#lang scribble/doc

@(require scribble/manual scribble/decode "../utils.ss")

@(define *base* "http://muvee-style-authoring.googlecode.com/svn/trunk/")
@(define *tut* (string-append *base* "tutorials/ReflectionsWithABounce/"))
@(define (tut-stage-url n) (string-append *tut* "S10000_ReflectionsWithABounce_Stage" (number->string n) "/"))
@(define (stage n heading) @make-splice{@list{@section{STAGE @(number->string n) : @heading} 
                                                      @bold{Style:} @link[(tut-stage-url n)]{S10000_ReflectionsWithABounce_Stage@(number->string n)}}})

@(define (tut-file n f) @filepath{@link[(string-append (tut-stage-url n) f)]{@f}})

@title[#:style 'quiet #:tag "Putting_a_Bounce_into_Reflections"]{Putting a bounce into the @onscreen{Reflections} style}

@margin-note{@bold{Tip:} Copy-paste the tutorial URL into the muveeStyleBrowser's
                  address box to get the styles for the various stages.}
@bold{Tutorial URL:} @link[*tut*]{tutorials/ReflectionsWithABounce}

The @onscreen{Reflections} style that comes with muvee Reveal, by design,
does not react much to the music track. We'll use that as an opportunity and
make pictures bounce to music. In the process, you'll learn about
animating effect parameters and how to access information about the music
track and use that information to determine an effect's behaviour.

This tutorial needs you to be familiar with @secref{Getting_Started}.
We'll also be getting into some depth coding up effect animations in muSE, so
it helps to familiarize yourself with (at least) the basics of muSE in
@secref{A_Gentle_Introduction_to_muSE}.

@local-table-of-contents[]

@stage[1]{Preparation}

Copy the @onscreen{Reflections} style. See @secref{Getting_Started} if you
don't know how to do that.
@indent{@bold{Style id:} @tt{S10000_ReflectionsWithABounce}}
@indent{@bold{Style name:} Reflections with a bounce}
@indent{@bold{Style description:} Your pictures bounce to the music on a reflecting surface.}
       
Launch muvee Reveal, add some pictures to the media panel and select your
@onscreen{Reflections with a bounce} style.

@stage[2]{Flight check}

In order to bounce the pictures, we need to @emph{move} it up and down in a
specific pattern. We therefore need to use the @secref{Translate} effect
on the pictures, animating the @scheme[y] parameter to do the bounce.

We first do a simple exercise to make sure we can translate pictures
correctly - we just move the pictures from the reflecting floor by
a fixed amount. Keeping in mind that positive values of @scheme[y] 
give you upward movement and negative values give you downward movement,
we apply a @secref{Translate} effect on the pictures with a @scheme[y]
value of @scheme[0.2].

We want to apply the translation to each picture *before* it is placed
on the reflecting surface and the paraphernalia (stars, circles, etc.) 
get added. We therefore need to look for @scheme[muvee-segment-effect]
and insert the translation at the segment level. 

@subsubsub*section{Segment level effects}

@margin-note{Refs: @secref{Anatomy_of_a_muvee}, @secref{The_segment_effect}}             
In a muvee, portions of input media such as pictures and video clips are
presented by themselves as @emph{segments}. For example, if you add a bunch
of pictures to the media panel, each picture gets shown for a few seconds
and then the style moves on to the next picture. Each of those occurrences
is called a @emph{segment} and the way a segment gets presented is 
dictated by @scheme[muvee-segment-effect].

@itemize{
  @item{From the muveeStyleBrowser, open your style's @filepath{data.scm}
        file by right clicking on your style and selecting @onscreen{Edit data.scm}.
        For the rest of the tutorial, you can keep muvee Reveal and your
        text editor for the @filepath{data.scm} file open simultaneously.}
  @item{Locate the definition point of @scheme[muvee-segment-effect] in the
        @filepath{data.scm} file.}
  }

You should be looking at the following piece of code -
@schemeblock[
(define muvee-segment-effect
  (effect-stack
    reflection-and-polygons-fx
    captions-fx))
]

The @scheme[captions-fx] specifies how to place a picture's captions on it
and the @scheme[reflection-and-polygons-fx] specifies that the picture together
with it caption text has to be reflected on a shiny surface and should have
some sprites moving about on the floor.


@itemize{
  @item{Add a @scheme[bounce] definition and insert it into the @scheme[effect-stack]
as shown below -
@schemeblock[
(code:comment "---- Add the following definition ----")             
(define bounce
  (effect "Translate" (A)
          (param "y" 0.2)))
(code:comment "--------------------------------------")

(define muvee-segment-effect
  (effect-stack
    reflection-and-polygons-fx
    captions-fx (code:comment "<<-- Remove )) from this line.")
    bounce)) (code:comment "<<-- Add this line.")
             
]
}
       
  @item{Save your @filepath{data.scm} file and click the play button in muvee Reveal
while holding down the Shift key. Notice that the picture now floats above
the floor instead of sitting on it. So @scheme["Translate"] works just
as it should.}
       }

@subsubsub*section{The location of @scheme[bounce] in the @scheme[effect-stack]}

@margin-note{Ref: @secref{effect-stack}}
We put the @scheme[bounce] at the end of the @scheme[effect-stack]. Doing so
shifts the pictures first, then places captions (relative to the original
unshifted picture location) and then reflects the entire scene on the shiny
floor.

Try changing the position of @scheme[bounce] within the @scheme[effect-stack].
What do you get when you do this -
@schemeblock[
(effect-stack
   bounce
   reflection-and-polygons-fx
   captions-fx)
]
or this instead -
@schemeblock[
(effect-stack
   reflection-and-polygons-fx
   bounce
   captions-fx)
]

(You will need to add some caption text for a picture to tell the difference
between placing @scheme[bounce] before and after @scheme[captions-fx].)

You've now got the basic stuff in place. Further on, we'll focus on 
exactly how to generate the bounce that we're looking for.

@stage[3]{The elementary bounce}

If you plot the height of a bouncing object against time, it will
look like the following graph -

@image["tutorials/image/bounce-curve.png"]

We can try to create such a bounce by hand as follows -
@schemeblock[
             
(define bounce
  (effect "Translate" (A)
          (param "y" 0.2
                 (#,(seclink "explicit-animation-curves" (scheme linear)) 0.1 0.19)
                 (linear 0.2 0.17)
                 (linear 0.3 0.13)
                 (linear 0.4 0.07)
                 (linear 0.5 0.0)
                 (linear 0.6 0.07)
                 (linear 0.7 0.13)
                 (linear 0.8 0.17)
                 (linear 0.9 0.19)
                 (linear 1.0 0.2))))
]

... but that's too tedious and we won't be able to synchronize
to music. So lets help ourselves and define a bounce animation
function that will put in all those @scheme[linear] animations for us.
@schemeblock[
(define (#,(seclink "Recursive_functions" (scheme bounce-anim)) height start stop time dt)
  (#,(seclink "Temporary_names_using_let" (scheme let)) ((t (math time + dt)))
    (#,(seclink "Conditional_evaluation" (scheme if)) (< t stop)
      (let ((p (math (t - start) / (stop - start))))
        (#,(bold (scheme linear)) t (math 4 * height * p * (1 - p)))
        (#,(seclink "Recursive_functions" (scheme bounce-anim)) height start stop (+ time dt) dt))
      (#,(bold (scheme linear)) stop 0.0))))

(define bounce
  (effect "Translate" (A)
    (param "y" 0.2
      (bounce-anim 
         0.2 (code:comment "Height")
         (code:comment "Convert from relative time to absolute time using progress function.")
         (#,(seclink "Time_specification" (scheme progress)) 0.0) (code:comment "Start time")
         (progress 1.0)(code:comment "Stop time")
         (progress 0.0) (code:comment "Initial time")
         1/20)))) (code:comment "20 animation points per second.")
                  
]

The @scheme[bounce-anim] function generates one bounce of height
@scheme[height] starting from absolute time @scheme[start] and
ending at absolute time @scheme[stop] in steps of @scheme[dt].
The @scheme[time] parameter is just to keep track of progress
over the animation.

If you tried that out, you'd have found the bounce to be really slow.
Lets speed it up by doing many bounces for each picture -

@schemeblock[
(define bounce
  (effect "Translate" (A)
    (param "y" 0.0
      (bounce-anim 0.2 (progress 0.0) (progress 0.1) (progress 0.0) 1/20)
      (bounce-anim 0.2 (progress 0.1) (progress 0.2) (progress 0.1) 1/20)
      (bounce-anim 0.2 (progress 0.2) (progress 0.3) (progress 0.2) 1/20)
      (bounce-anim 0.2 (progress 0.3) (progress 0.4) (progress 0.3) 1/20)
      (bounce-anim 0.2 (progress 0.4) (progress 0.5) (progress 0.4) 1/20)
      (bounce-anim 0.2 (progress 0.5) (progress 0.6) (progress 0.5) 1/20)
      (bounce-anim 0.2 (progress 0.6) (progress 0.7) (progress 0.6) 1/20)
      (bounce-anim 0.2 (progress 0.7) (progress 0.8) (progress 0.7) 1/20)
      (bounce-anim 0.2 (progress 0.8) (progress 0.9) (progress 0.8) 1/20))))
]

We're now able to generate multiple bounces for each picture, with the
bounce points at the time of our choice. Now, all that's left is to 
align the times to appropriate events in the music track.

@section{Interlude: Cut hints}

When muvee Reveal analyzes a music file, it detects events such as drum hits. For each such
detected event, it records a time-value pair, where the time says when the event occurred
and the value (in the range 0.0 to 1.0) says how strong the event is. The events
based on broad spectrum analysis of the music data are called @emph{cut hints}. You can access 
this data in a style using the @seclink["Music_descriptors"]{@scheme[cut-hints]} function. 
Although cut hints are computed per music file, the @scheme[cut-hints] function consolidates 
the hints for all the music files used in the muvee's music track.

For example, @scheme[(cut-hints 2.0 5.0)] extracts the cut hints between 2.0 seconds
and 5.0 seconds into the muvee and might give you a list like -
@schemeblock['((2.3 . 0.2) (3.5 . 0.7) (4.5 . 0.1))]

Within an @scheme[effect] expression, you can use the @scheme[_start] and @scheme[_stop] implicit
parameters to access the time interval during which the effect will be active.
You can therefore extract the cut hints using - @scheme[(cut-hints start stop)].

@stage[4]{Bouncing to events in the music track.}

We want to generate one bounce between every two consecutive cut hints within
a picture's presentation interval. That way, the bounce point will synchronize
with the cut hint. But in order to get cut-hints, we need a music track.
So go ahead and add some music now. For lack of a better suggestion, you can add the
sample music that comes with muvee Reveal which you can find in your "Music"
folder. Make sure you put in about 15 pictures for every minute of music that 
you add.

Given a cut-hints list such as @schemeblock['((2.3 . 0.2) (3.5 . 0.7) (4.5 . 0.1))]
we need to generate a matching number of @scheme[bounce-anim] expressions like we
did above in stage 3. We can, again, define a function to make the repeated calls.

@schemeblock[
(define (bounce-to-hints height start stop hints dt)
  (case hints
    (() 
     (bounce-anim height start stop start dt))
    (((t . v) . hints*) 
     (bounce-anim height start t start dt)
     (bounce-to-hints height t stop hints* dt))))
]

Now we just have to use @scheme[bounce-to-hints] in our @scheme[bounce]
effect to generate the animations.
@schemeblock[
(define bounce
  (effect "Translate" (A)
    (param "y" 0.0
      (bounce-to-hints 
         0.2 
         start 
         stop 
         (cut-hints start stop) 
         1/20))))
]

Make some muvees with different music tracks and watch the pictures bounce
to the beat points. 

@stage[5]{Selecting better bounce points}

At the end of stage 4, you'll notice that on some occasions there may be too many
bounces or the bounces may be too close to each other for taste. In this stage,
we'll work on selecting a nice set of bounce points for each picture.

There are many ways to filter hints. For example-
@itemize{
  @item{Select only the hints whose strength is above a certain threshold.}
  @item{Limit the number of hints selected for each picture, according to the
        hint strength - i.e. pick the @scheme[N] strongest hints for a fixed @scheme[N].}
  @item{Set a lower limit on the time difference between two consecutive hints.}
  }
You can even combine many of these techniques, but for illustration, we'll
use the second approach - i.e. limit the number of hints per picture. In our
case, this limits the number of times we allow a picture to bounce. We do this
by first sorting the hints according to decreasing order of their strengths,
picking a dozen of the strongest from them and then resorting the hints into 
time order.

@schemeblock[
(define (select-strongest-hints hints N)
  (let ((strongest-to-weakest (sort hints (fn ((t . v)) (- v))))
        (N-strongest (take N strongest-to-weakest))
        (time-order (sort N-strongest first)))
    time-order))

(define bounce
  (effect "Translate" (A)
    (param "y" 0.0
      (bounce-to-hints 
         0.2 
         start 
         stop 
         (select-strongest-hints (cut-hints start stop) 12)
         1/20))))
]

@stage[6]{Generating a better bounce}

The bounce we have at this point is not very physical. For one thing,
the bounce speed seems to vary from one bounce to the next whereas natural
objects don't do that. For natural objects, the bounce duration will be
longer only if it bounces higher. The solution to this is therefore quite simple. 
We make the height of the bounce proportionate to its duration.

Change the definition of @scheme[bounce-to-hints] to -

@schemeblock[
(define (dur->height start stop)
  (math (stop - start) / 5.0))

(define (bounce-to-hints start stop hints dt)
  (case hints
    (() 
     (bounce-anim (dur->height start stop) start stop start dt))
    (((t . v) . hints*) 
     (bounce-anim (dur->height start t) start t start dt)
     (bounce-to-hints t stop hints* dt))))
]

.. and the definition of @scheme[bounce] will have to now
drop the height parameter to @scheme[bounce-to-hints].

@schemeblock[
(define bounce
  (effect "Translate" (A)
    (param "y" 0.0
      (bounce-to-hints 
         start 
         stop 
         (select-strongest-hints (cut-hints start stop) 12)
         1/20))))             
]

And just for completion, here is the entire bit of
custom code you need to add to the Reflections style
to get your pictures bouncing -
@schemeblock[
(define (bounce-anim height start stop time dt)
  (let ((t (+ time dt)))
    (if (< t stop)
      (let ((p (math (t - start) / (stop - start))))
        (linear t (math 4 * height * p * (1 - p)))
        (bounce-anim height start stop (+ time dt) dt))
      (linear stop 0.0))))

(define (dur->height start stop)
  (math (stop - start) / 5.0))

(define (bounce-to-hints start stop hints dt)
  (case hints
    (() 
     (bounce-anim (dur->height start stop) start stop start dt))
    (((t . v) . hints*) 
     (bounce-anim (dur->height start t) start t start dt)
     (bounce-to-hints t stop hints* dt))))

(define (select-strongest-hints hints N)
  (let ((strongest-to-weakest (sort hints (fn ((t . v)) (- v))))
        (N-strongest (take N strongest-to-weakest))
        (time-order (sort N-strongest first)))
    time-order))

(define bounce
  (effect "Translate" (A)
    (param "y" 0.0
      (bounce-to-hints 
        start 
        stop 
        (select-strongest-hints (cut-hints start stop) 12)
        1/20))))

(define muvee-segment-effect
  (effect-stack
    reflection-and-polygons-fx
    captions-fx
    bounce))
]

@section{Beyond}

Feel free to play around and customize the bounce according to your
own taste. Here are a few things to try -
@itemize{
  @item{Make the pictures bounce higher if the bounce starts on
        a strong hint value.}
  @item{Filter out hints that are too close to each other. One approach
        is to use a time threshold, but you can also try
        varying the time threshold depending on hint strength value.}
  @item{Use similar techniques to twist the pictures instead of bouncing
        them on the floor.}
  }
