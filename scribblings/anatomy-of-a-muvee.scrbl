#lang scribble/doc
@(require scribble/manual)

@title{Anatomy of a muvee}

A muvee puts together user content in a specific way that is described
in the diagram below.

@image["image/AnatomyOfAMuvee.png"]

@subsubsub*section{Video and picture segments}
User media is selected for inclusion in the muvee as a sequence of
overlapping segments. A picture segment shows one picture for a duration
and a video segment shows a portion of one of the input video files
for a duration.

@subsubsub*section{Segment effects} 
Each video or picture segment can be given a
treatment that is specific to the segment. These are usually referred
to in this documentation as @italic{segment effects}. For example, pictures
might be presented in a photo-frame format and video might be
presented within a TV graphic. These will be segment effects.

@subsubsub*section{Transitions}
When two segments overlap, a @italic{transition} is used to specify how to
compose the two segments into the scene. Examples of transitions
include the traditional @italic{dissolve}, different types of @italic{wipes}, etc. A
zero duration transition is known as a @italic{cut}.

@subsubsub*section{The global effect}
The global effect determines a uniform treatment that is applied to
the entire muvee. For instance, this could be a "sepia" tone that is
used to give the muvee an aged look.

@subsubsub*section{The music track}
This consists of all the music files given in muvee Reveal's "music"
panel. The style has no control over the composition of the music
track.

@section{Automatic editing}

@image["image/MuveeProcess.png"]

The muvee editing engine - which we call @italic{The Constructor} -
automatically decides the timing of each segment and which piece of
the user's media goes into each of them. The constructor takes into
account the specifications provided by the muvee Reveal user such as
muvee duration and magic moments when generating the segment
structure.

A style customizes the result of constructor's output by providing its
own treatments for the segments, transitions and the muvee as a whole.

As with all things, a bit more is involved. Before the construction
process begins, all the video, pictures and music are analyzed for
features. Video is analyzed for faces, quality, brightness and
movement. Pictures are analyzed for face regions and aspect
ratios. Music is analyzed for beats. These analyses are also factored
in by the constructor. For example, the timing of the segments is tied
to the beats in the music to give the muvee a music video-ish feel,
portions of the video with faces can be given a higher chance of
inclusion into the muvee, etc.  

Although the diagram above simplifies the notion of a style, a style
does have some say over how the analyses are used by the
constructor. Styles therefore serve as a panel of switches and sliders
you can tweak to influence the contructor.
