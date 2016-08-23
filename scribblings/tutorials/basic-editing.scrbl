#lang scribble/doc

@(require scribble/manual scribble/decode "../utils.ss")

@(define *base* "http://muvee-style-authoring.googlecode.com/svn/trunk/")
@(define *tut* (string-append *base* "tutorials/BasicEditing/"))
@(define (tut-stage-url n) (string-append *tut* "S10000_BasicEditing_Stage" (number->string n) "/"))
@(define (stage n heading) @make-splice{@list{@section{STAGE @(number->string n) : @heading} 
                                                      @bold{Style:} @link[(tut-stage-url n)]{S10000_BasicEditing_Stage@(number->string n)}}})

@(define (tut-file n f) @filepath{@link[(string-append (tut-stage-url n) f)]{@f}})
                                
@title[#:style 'quiet]{Basic editing}

@margin-note{@bold{Tip:} Copy-paste the tutorial URL into the muveeStyleBrowser's
                  address box to get the styles for the various stages.}
@bold{Tutorial URL:} @link[*tut*]{tutorials/BasicEditing}

Here we show you aspects of a muvee style that is likely to cross-cut
all the styles that you might develop. It is therefore worth working
through the concepts in this tutorial so you can tweak the editing behaviour
of your style to match your audio-visual effects. All the action in this 
tutorial happens in the style's @filepath{data.scm} file so that's the 
file to direct your attention to.

@local-table-of-contents[]

@stage[1]{Starting from the S10000_BlankTemplate}

@itemize[#:style 'ordered]{
  @item{Make sure muvee Reveal isn't running.}
  @item{Start by copying the @tt{Blank template} style. If you're unsure
        how to do this, refer to @secref{Getting_Started}. The rest of the
        tutorial assumes that your style has the id @tt{S10000_MyBasicEditingStyle}.
        Do change the name of the style to something like ``My basic style''
        and its description to, say, ``A masterpiece in the works.'' just
        so you can distinguish it from the original.}
  @item{Launch muvee Reveal and your new style will show up in Reveal's
        styles panel, ready for action.}
  }

At this stage, your style consists of just two lines of code,
apart from the comments. 
@schemeblock[
(code:comment "No parameters yet.")             
(#,(seclink "The_style-parameters_section" (scheme style-parameters)))

(code:comment "Specify a uniform cutting pattern without any segment variations.")
(#,(seclink "Segment_duration_pattern" (scheme segment-durations)) 2.0)
]

This style, although very minimal, already gives you a lot. For example, you can
use pictures, video and music with it, your pictures get an automatic Ken-Burns
effect based on face detection and your video is automatically summarized to
the duration you give, or to the music duration, depending on your setting. 
Of course, you can use highlights and exclusions on your video to control
the content. Your style responds to pretty much everything that the muvee Reveal
interface allows you to specify (... except captions, which we'll defer).

@subsubsub*section{Playing with your new style}
Since this tutorial is about editing logic, pacing and music response, we suggest
you do at least one of the two below -
@itemize{
         @item{Add about 50 pictures and 1 minute of music that has significant
               soft and energetic portions. Then go to the @onscreen{Personalize}
               panel and select @onscreen{Use it all} mode. muvee Reveal tries to
               fit all your pictures into the duration that you specify, therefore
               if you do not select @onscreen{Use it all}, you will not be able
               to see the effects of pacing changes in this tutorial.}
         @item{.... or add at least 5 minutes of video and 1 minute of music.
               If you're adding a longer piece of music, add proportionately more
               video.}
         }

Now select your new style and make some muvees. Try different media, personalization
settings, etc. You may notice that captions don't work yet. We'll come to that later
in this tutorial. If you're a new-comer to muvee Reveal and automatic editing,
you might find the tutorials at @link["http://community.muvee.com"]{the muvee Maniacs forum}
useful.

@margin-note{If you've already installed @link["http://www.drscheme.org"]{DrScheme},
it will chosen as the editor for @tt{.scm} files.}
To work through the following stages, you'll need to edit your style's
@filepath{data.scm} file. If you have your style open in the muveeStyleBrowser,
you can right-click on your style and select the @onscreen{Edit data.scm} command
to open it in a text editor.  

@subsubsub*section{!!! Important Note !!!}
Whenever you modify your style's @filepath{data.scm} file and want to see the effect
of your changes on your muvee, hold the @onscreen{Shift} key and click on the play button
in Reveal's interface. (This facility is available starting from the March 2009 release 
of muvee Reveal.) The play button usually just plays the muvee if you've made, but
in this case you want to recompute the muvee and you indicate that by holding down the
@onscreen{Shift} key as you click the play button.

You now have the beginnings of your style.

@stage[2]{Playing around with editing pace}

If you played around with the ``Stage1'' style, you'll have noticed that
your style edits at the same pace no matter what piece of music you give it. 
``Pace'' refers to the overall rate of happenings in the muvee. A faster paced
muvee will have more pictures shown per minute than a slower paced one, at the
very least. We'll add some user level control of the editing pace
in this stage and follow it up with music driven pace control in the next one.

Add a style parameter named @scheme{PACE} and directly specify the @scheme[segment-durations]
using @scheme[PACE] -

@indent{@bold{IMPORTANT:} Changing @scheme[style-parameters] needs 
             muvee Reveal to be relaunched to take effect.}

@schemeblock[
(code:comment "muSE v2")
(style-parameters 
 (code:comment "Specify a PACE slider with a default of 2.0,")
 (code:comment "a minimum value of 0.5 and a maximum of 8.0.")
 (#,(seclink "continuous-slider" (scheme continuous-slider)) PACE 2.0 0.5 8.0))

(segment-durations PACE)
]

Now when you open the ``Style settings'' panel, you should see a @scheme[PACE]
slider that you can twiddle to make your style edit faster (to the left)
or slower (to the right). Notice that even though you make the muvee go faster
or slower, the transition points (a.k.a. ``cut points'') are synchronized to the
music events.

@stage[3]{Better PACE control}

The @scheme[PACE] slider we defined in Stage 2 above is functional, but is not quite
what we'd like. There are two problems with it -
@itemize{
         @item{Moving the slider to the left causes the style to edit @emph{faster} and
               moving to the right causes it to edit @emph{slower}. This is counter 
               intuitive to the notion of @emph{pace}.}
         @item{The range from 4x faster to normal speed takes up only about 30%
               of the slider's length compared to the range from normal speed to
               4x slower. Ideally we'd like both to take up the same range to match
               our intuition of Nx faster or slower.}
         }

This kind of issue arises very often when you are designing sliders for user control
and is therefore worth paying some attention to. You @bold{always} want to make your
sliders correspond to the user's intuition as much as you can - by making it
control one independent aspect of the production, making it always @emph{increase}
something when you move it from left to right and by making it increase 
@emph{proportionately}.

@indent{@bold{IMPORTANT:} Changing @scheme[style-parameters] needs muvee Reveal to be relaunched to take effect.}

To achieve all of that for our @scheme[PACE] slider, we turn @scheme[PACE] into a 
logarithmic control as follows -
@schemeblock[
(code:comment "muSE v2")
(style-parameters
 (continuous-slider PACE 0.0 -2.0 2.0))

(segment-durations (/ 2.0 (pow 2.0 PACE)))
]

The expression @scheme[(/ 2.0 (pow 2.0 PACE))] is the Scheme code equivalent of the
mathematical form @math{2.0 / (2.0 @superscript{PACE})} which becomes @scheme[0.5] when @scheme[PACE]
is @scheme[-2.0] (the left extreme point) and becomes 8.0 when @scheme[PACE] is @scheme[2.0]
(the right extreme point). 

If the above way of writing mathematical expressions doesn't suit you, consider using
@scheme[math] to get a more familiar notation. With @scheme[math], the above @scheme[segment-durations]
line becomes -
@schemeblock[
(segment-durations (math 2.0 / (2.0 pow PACE)))             
]
See @secref{Mathematical_expressions_in_Scheme} for more discussion on the topic.

We now have a @scheme[PACE] slider that goes from ``4x slower'' to ``4x faster'' more
evenly than it did before.

@stage[4]{Making the editing pattern respond to music}

Controlling the pace of your edits using a slider is fine and fun, but if you tried
your style with many types of music with some dynamics, you soon begin to
want to be able to move the @scheme[PACE] slider depending on the music - for example, you might
want to edit faster during the more energetic portions of a music and slower during
the softer portions.

Though you cannot control the @scheme[PACE] slider @emph{during} muvee playback,
you can encode the music dependence into your style using the concept called 
@tech{segment duration transfer curve}. During music analysis, muvee Reveal 
computes a @scheme[loudness] function that varies in the range @scheme[0.0] to @scheme[1.0]
over the course of the music. Obviously, during the louder sections of the music, the loudness 
value is closer to @scheme[1.0] and during the softer sections, it is closer to @scheme[0.0].

The segment durations scale up and down based on the value of @scheme[loudness] as specified by
the @scheme[segment-duration-tc]. Here is what you can add to Stage 3 to get music-dependent 
editing pace.

@schemeblock[             
(segment-duration-tc (code:comment "loudness   scaling-factor")
                     0.0   6.0
                     0.5   1.0
                     1.0   1/4)
]             

The first column gives the music loudness and the second column gives
the scaling factor to be applied to each segment duration when the loudness
of the music during the segment is that value. The value of @scheme[6.0],
for example, says that the editing pace when the loudness value is near
@scheme[0.0] should be 6x slower than the pace specified by the 
@scheme[segment-durations] expression. The value of @scheme[1/4] for
loudness of @scheme[1.0] means the cutting pace will be 4x faster 
than normal pace for loud portions of the music.

You only specify certain ``knee'' points in the transfer curve and
scaling factors for other loudness values will be determined by proportional
interpolation.

See @tut-file[4 "data.scm"] for all the style code up to this point.
You now have a style whose pace you can control and which responds to the
dynamics of the music.

@stage[5]{Adding transitions}

In our style so far, each segment changes to the next one abruptly. Such a
transition is known in editing parlance as a @tech{cut}. Cuts are effective 
when the music is energetic and the editing pace is fairly high. However, 
you can enhance the emotive appeal of the slower parts of your music by
using soft transitions when @scheme[loudness] goes low.

First, you'll need to learn how to add transitions to your style.
The most important thing you need to do is to @scheme[define] the
@scheme[muvee-transition] symbol to an expression that describes
a transition. In our case, we'll start simple by putting in a
cross-fade transition. We'll stick to this simple transition for now
and leave the construction of effects and transitions to a separate
tutorial.
@schemeblock[
(define muvee-transition (effect "CrossFade" (A B)))
]

Once you add the above expression to the Stage 4 style, you'll get cross fades
*everywhere* instead of cuts.

@subsubsub*section{Basic transition specification}

The transition duration is decided by the @scheme[preferred-transition-duration]
which defaults to @scheme[1.0] when not specified. You can change the value
to a smaller value first, to shorten the transition durations for the normal
pace case -
@schemeblock[
(preferred-transition-duration 0.4)
]

You can disallow transitions for ultra-short segments by changing the
``minimum segment duration for transition'' setting as follows -
@schemeblock[
(min-segment-duration-for-transition 0.8)
]
... which says that if we're creating a segment that is shorter than
0.8 beats, don't stick any transitions from or to this segment.

Putting the three together, we have a full transition specification -
@schemeblock[
(preferred-transition-duration 0.4)
(min-segment-duration-for-transition 0.8)
(define muvee-transition (effect "CrossFade" (A B)))
]

See @tut-file[5 "data.scm"] for all the style code up to this point.

@stage[6]{Making transition durations respond to music}

Now we have transitions adding to the character of the style.
Play around with it and try different kinds of music. In this
stage, we're going to introduce a subtlety that is often used
by human editors, but something that most viewers are seldom aware of -
that @emph{it is generally nicer to have longer transitions when the music
is soft and shorter transitions when the music is energetic.}

Like what we did with segment durations in Stage 2 above,
we want to tie the transition durations to the music loudness.
.. and just like what we did with @scheme[segment-durations], we have
a corresponding @tech{transition duration transfer curve} to help us
specify the relationship.

@schemeblock[
(transition-duration-tc (code:comment "loudness scale-factor")
                        0.00    3.00
                        0.50    1.00
                        1.00    0.25)
]

The first column specifies the loudness value and the second column specifies
a corresponding factor that multiplies with the preferred transition
duration indicated by the @scheme[preferred-transition-duration] expression.


See @tut-file[6 "data.scm"] for all the style code up to this point.


@stage[7]{Adding a MUSIC RESPONSE control}

We have a fairly complete basic style now and more importantly we're aware 
of all the basic aspects of style authoring that have to do with
its editing behaviour. We'll top it off by wanting just a bit more -
to be able to dictate the extent to which we want our style to
respond to music. This is a good exercise in parameter design
and we'll leave the details for you to work out as an exercise.

@indent{@bold{IMPORTANT:} Changing @scheme[style-parameters] 
                  needs muvee Reveal to be relaunched to take effect.}

@subsubsub*section{Specification of @scheme[MUSIC_RESPONSE]}
What we want is to add a new control called @scheme[MUSIC_RESPONSE]
which when set to 0.0 makes the style behave blandly even if the
music is changing wildly from soft to loud and back (as though
we did Stage 3 but had transitions), and which when
set to 1.0 causes @bold{all} aspects of the style that we've
defined so far to respond to music - exactly like Stage 6.

@subsubsub*section{Solution}
...

Ok.. here is the full code for stage 7 - @tut-file[7 "data.scm"].

@stage[8]{Some polish}

In this stage, we're going to add a bit of polish to the style.

@subsubsub*section{Title -> Body and Body -> credits transitions}

In Stage 6, we added transitions, but if you noticed, the muvee begins
abruptly after the title ends and at the end of the muvee, it abruptly
jumps to the credits section. That's not very smooth since the main muvee
itself uses cross-fades to soften things up. So now we use the same 
cross-fade transition for the title->body and body->credits jumps
as well.

Add the following two lines to the end of your @tut-file[8]{data.scm} file -

@schemeblock[
(muvee-title-body-transition muvee-transition 0.5)
(muvee-body-credits-transition muvee-transition 0.5)
]

Since we've already defined @scheme[muvee-transition], we can
re-use that for the title->body and body->credits transitions. Of course,
you can use different transitions for these if you want to.

Try it out. Looks better?

@subsubsub*section{Captions}

If you'd added captions for your pictures or video, you might have noticed
that they didn't turn up when you viewed your muvees. This is because each 
style has to explicitly describe how captions are to be presented and we
haven't done that yet for our new style.

You can easily specify a ``standard treatment'' for captions by defining
@scheme[muvee-segment-effect] to @scheme[muvee-std-segment-captions].

@schemeblock[
(define muvee-segment-effect muvee-std-segment-captions)
]

@scheme[muvee-std-segment-captions] scans all the
captions that need to be presented during its application period and
shows them as indicated in muvee Reveal's captions UI. Since it is
a normal @scheme[effect], it is possible to combine this with other
effects to create more sophisticated captions like those in
muvee Reveal's @onscreen{Reflections} style. We'll defer that
to another tutorial.

@subsubsub*section{Strings}

When you open your style's settings panel, you see ugly looking names for
your parameters and their ranges - @scheme[PACE], @scheme[PACE_MIN], @scheme[PACE_MAX], etc.
Lets clean that up by writing down some nice labels for our precious 
user-level controls, since we put in so much effort into getting them
behave nicely.

The key file here is @filepath{strings.txt}, which you can edit by right clicking
on your style in the muveeStyleBrowser and selecting @onscreen{Edit strings.txt}. 

Your current strings.txt file probably contains the following two lines -

@schemeblock[
STYLEDESC	en-US	A masterpiece in the works.
STYLENAME	en-US	My basic style
]

Each line in the @filepath{strings.txt} file specifies three items 
separated by a single @tt{<tab>} character -
@itemize[#:style 'ordered]{
         @item{The ID of the string.}
         @item{The language code.}
         @item{The string for the ID in that language code.}
         }

So, for example, the line
@schemeblock[
STYLENAME	en-US	My basic style
]
says - @tt{STYLENAME}'s US-English text is ``@tt{My basic style}''.

You can add similar strings for each parameter that your style exposes.
muvee Reveal's UI will look up these strings and use them instead
of showing @tt{PACE}, @tt{PACEMIN} etc.

So edit your @filepath{strings.txt} and add the following lines -

@schemeblock[
PACE	en-US	Pace
PACE_MIN	en-US	Slow
PACE_MAX	en-US	Fast
MUSIC_RESPONSE	en-US	Music response
MUSIC_RESPONSE_MIN	en-US	Inverse
MUSIC_RESPONSE_MAX	en-US	Normal
]

@indent{@bold{WARNING:} Do not copy-paste the above lines into your strings.txt.
Copy from the original file @tut-file[8]{strings.txt} instead to get the correct
formatting.}

Here is a link to the @tut-file[8]{strings.txt} file.

@subsubsub*section{Localization}

Ideally, you'll want your strings to be localized in all the languages that you
want your style to work on, but we'll stop with English for the moment. You can
take a look at the @filepath{strings.txt} files in muvee Reveal's bundled styles
for examples of how to add UTF-8 encoded strings in other languages. Its not
very different from what we did here, you just need to know the language codes.

@section{Now what?}

You now have a style that shows interesting music response characteristics and
does some simple transitions. You now also know how to get there in an 
incremental fashion. You can go ahead and add more complexity to your style
to make it more interesting and our @link["http://muvee-style-authoring.googlecode.com/svn/doc/main/index.html"]{documentation}
and @link["http://groups.google.com/group/muvee-style-authoring"]{discussion group}
are there to help you get to where you want to go.

@section{Appendix}

@subsection{Mathematical expressions in Scheme}

In Scheme, operators always come first in @scheme[(....)] expressions. It is easy to get
used to it if you read these expressions operationally - for example, @scheme[(/ (+ a b) (- a b))]
can be read as @emph{``@bold{divide} the @bold{sum} of a and b by the @bold{difference} of a and b''.} 

The Scheme notation is unambiguous and no explanation is needed beyond the @emph{operator
first} rule. If you need regular mathematical notation, you can write the same expression as 
@schemeblock[(math (a + b) / (a - b))]

@indent{@bold{IMPORTANT:} You *must* leave a space surrounding the mathematical operators.
             You cannot write @scheme[(math a*b+c)], for instance. You must write @scheme[(math a * b + c)]. This is because @scheme[a*b+c] is a valid Scheme symbol.}

The @scheme[math] form supports the following kinds of expressions -
@schemeblock[
(math a + b) = (+ a b)
(math (sin x) * (cos y)) = (* (sin x) (cos y))
(math (a * b) + c) = (+ (* a b) c)
(math a * b * c * d) = (* a (* b (* c d))) = (* a b c d)
(math a * b + c) = (math a * (b + c)) = (* a (+ b c))
(math a * b + c * d) = (math a * (b + (c * d))) = (* a (+ b (* c d)))
(math (a * b) + (c * d)) = (+ (* a b) (* c d))
]

