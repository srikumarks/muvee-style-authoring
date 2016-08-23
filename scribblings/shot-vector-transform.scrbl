#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{The shot vector transform}

@New!{X}

The constructor works by allocating segments to the media items
specified by the user in muvee Reveal's media panel. Certain kinds of
productions need more control over the structure of the input media in
order to be possible. For example, a style may be wish to present three
photos at a time. In such a case, you may not want the duration for
which a three-photo composition is shown to be three times as long as
the time the style would spend on a single photo. The shot vector
transform mechanism permits you control over such aspects of the
construction through the manipulation of shots passed by the user before
the constructor gets to see them.

The shot vector transform is a function that takes a 
@link["http://muvee-symbolic-expressions.googlecode.com/svn/api/group__Vectors.html"]{vector} 
of shots and is expected to return a vector shots. The returned shot vector is what
is seen by the constructor. The shots passed in the input can be
reused in the output with or without modification. The function may also
insert new shots or decide not to show certain shots specified by the
user.

@schemeblock[
(define (muvee-shot-vector-transform shotvec)
   ....
   result-shotvec)
]

@scheme[shotvec], as the name suggests, is a vector of shot objects and
@scheme[result-shotvec] is the transformed shot vector. The simplest
shot vector transform is therefore the identity function.

@section{The shot object}

The shot object represents a media item given by the user. It can be a photo,
a segment video clip or an inter-title card. 

Each photo is represented using its own shot object. So is each inter-title card.

Video clips have a more complicated relationship to the items specified by the user. 
All video clips are split up into shots according to a) the shot boundaries detected
in the video, b) the excluded sections and c) highlights. Each highlight is assigned
its own shot object and subsumes any shot boundaries within it. All excluded material
is thrown away and does not have any representation in the shot vector.

The shot object provides access to some of the properties of the media items,
some of which can be changed. In the code below we assume that @scheme[shot] stands
for a shot object.

@section{Basic shot properties}

@scheme[shot.file-name]: (read-only)
@indent{Full path to the media file.}

@scheme[shot.attribs]: (read-write)
@indent{A list of symbols indicating shot attributes. Symbols can be one or more
          of @scheme[sync-boost], @scheme[image], @scheme[video] or @scheme[inter-title].
          To tell whether a shot is video, you can do @scheme[(find 'video shot.attribs)].}

@scheme[shot.min-duration-secs]: (read-write)
@indent{On input, contains the "minimum duration" setting indicated by the user for 
           photos, taking into account both the global setting in the "Personalize" panel
           as well as any photo-specific setting. This field is irrelevant for video.}

@scheme[shot.id]: (read-only)
@indent{The unique ID (number) of the media panel item that this shot is associated with. All 
            shots that were created from a single media panel item will have the same @scheme[id]
            property. This allows you to regroup the shots to be isomorphic to the media panel if
            so desired.}

@scheme[shot.mtime]: (read-only)
@indent{A list of the form @scheme[(media-start-time media-end-time)] that specifies the media
          interval within a video file that the shot represents. Applicable only to video shots
          and irrelevant for images and inter-titles.}

@scheme[shot.captions]: (read-only)
@indent{A list of the form @scheme[((from1 to1 text1) (from2 to2 text2) ....)] if the user 
          has specified captions for the shot, or @scheme[()] if no caption is set for the shot.
          Photos will have at most one caption but videos can have more than one. Caption text
          might consist of a single line of text or two lines separated by a line break "\n"}

@scheme[shot.highlights]: (read-only)
@indent{If the shot is a highlight, then this will be a list of the form @scheme[((from to))]. If
           the shot has no highlights or is not video, this property will be @scheme[()].}

@section{Presentation properties}

Shot objects have some properties that can be set to control their presentation in 
ways that can be more flexible than the @scheme[muvee-segment-effect] mechanism.
All presentation properties of shots are unset upon input - i.e. only the shot
vector transform can set these properties.

All presentation properties can be used with both @scheme[put] and @scheme[get].
However, when you do, say, @scheme[(put shot.treatment my-fabulous-effect)], it does not 
replace the previous property, but is combined with it to create a composite treatment. 
Since there is seldom any need for a style author to replace a presentation property
after it being set, since only the shot vector transform can set it anyway, this auto-combination
approach is more useful.

@subsection{@scheme[shot.treatment]}

A shot's "treatment" is an effect that is applied to the media item prior to all other
style specified effects - i.e. treatments are the "inner most" effects applied to media.
Think "color treatment" and you're be roughly there.

@subsection{@scheme[shot.presenter]}

Intended to provide total control over the presentation of segments assigned to this shot.
A "presenter" function is of the form -

@schemeblock[(fn (_input-effect) ... _output-effect)]

In other words, a presenter is an effect transformer, which takes an 
effect (see @secref["About_effects_and_transitions"]), munges it and returns
another. The simplest presenter is therefore the identity function.

At construction time, if a shot has a presenter set, the constructor will pass it
the effect specified using @scheme[muvee-segment-effect] and will use the effect
returned by the presenter in place of that specification. This allows a presenter
to override the segment effect for a single shot easily.

Presenters are combined at @scheme[put] time using simple function composition.

@subsection{@scheme[shot.entry-effect] and @scheme[shot.exit-effect]}

These are effects and their composition behaves similar to @scheme[shot.treatment].
The only difference is the times at which these effects are used. 
The @scheme[shot.entry-effect] is applied in addition to the segment presentation
at the @emph{beginning} of the first segment containing media from the shot. Similarly, the
@scheme[shot.exit-effect] is applied in addition to the segment presentation at the
@emph{end} of the last segment containing media from the shot.

The constructor always shows media in the order specified in the media panel, therefore
all the other segments showing media from the shot are guaranteed to appear between the
segments containing exhibiting the entry effect and the exit effect.

@section{Utility functions}

Some utility functions are provided for creating new kinds of shots for use within the
result shot vector. These allows a style to insert stock media, special algorithmically
driven segments, etc. Note that all new shot objects @emph{must} be given valid shot ids.

@defproc[(make-video (path-to-file string) (property-object object)) shot-object]{
Creates a video shot object with the properties as specified in the 
        @scheme[_property-object].}


@defproc[(make-image (path-to-file string) (property-object object)) shot-object]{
Creates a photo shot object with the properties as specified in the
        @scheme[_property-object]. For photo shots, it is useful to specify the
        @scheme['min-duration-secs] property as in the example below -
        
                @schemeblock[
                             (make-image (resource "stock/art.jpg") 
                                         (object ()
                                                 'id shot.id
                                                 'min-duration-secs 20.0))]}




