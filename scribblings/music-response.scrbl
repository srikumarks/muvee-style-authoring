#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{Controlling a style's music response}

The @seclink["Automatic_editing"]{Constructor} sets up the timing for each portion of the input media given by the user. That is, it selects clips from the video material and arranges pictures into a timeline with many aspects of this construction driven by music characteristics. A style can specify how the constructor goes about doing this by setting several controls, which we describe here.

@section{Segment duration pattern}

You can give a looping sequence of segment lengths which the constructor will try to obey when placing pictures and video into the timeline. You do this using the @scheme[segment-durations] operator. For example -
@schemeblock[(segment-durations 2.0 4.0)]
will cause segments 1, 3, 5, etc. to be half as long as segments 2, 4, 6, etc. The units of these duration values are @emph{beats} which relate to the tempo of the music. You can give as many of these duration values to loop through. Such a loop is useful to create some variety in the edit.

@section{Segment duration scaling factor}

A (human) music video editor will tend to make slower edits when the music is quiet and faster edits when the music becomes energetic. You can simulate the same effect using what we call a @deftech{segment duration transfer curve}. This curve derives a scaling factor for segment durations as determined by the @seclink["Segment_duration_pattern"]{segment duration pattern} depending on the music's @scheme[loudness] value at the time of the edit.

This transfer curve is specified as follows -
@(define-syntax-rule (subsym sym sub) (elem (scheme sym) (subscript sub)))
@schemeblock[
(code:comment #, @t{@hspace[19]loudness-level@hspace[2]scaling-factor})
(segment-duration-tc 0.0             #,(subsym _scale "0")
                     #,(subsym _level "1")          #,(subsym _scale "1")
                     #,(subsym _level "2")          #,(subsym _scale "2")
                     ....
                     1.0             #,(subsym _scale "N"))
]
where @scheme[#,(subsym _level "k")] is greater than @scheme[#,(subsym _level "k-1")].

What an expression like that specifies is a piece-wise linear curve connecting the music loudness in the range @scheme[0.0-1.0] to a scaling factor. For instance, if you want to say that ``cutting speed at loudness=1.0 should be 4 times faster than the cutting speed at loudness=0.0'', you would define the transfer curve like this -
@schemeblock[
(segment-duration-tc 0.0 1.0
                     1.0 0.25)
]
The scaling factor for loudness values like 0.5 will be determined by proportional (linear) interpolation between the values for the nearby points - which are in this case 0.0 and 1.0.

Note that you can expressions based on, say, style parameters to calculate the level values as well as the scaling factor values. For example -
@schemeblock[
(style-parameters 
 (continuous-slider SPEED 0.0 -2.0 2.0)
 ....)

(segment-duration-tc 0.0 (/ 3.0 (pow 2 SPEED))
                     1.0 (/ 0.8 (pow 2 SPEED)))
]

@section{Transition duration scaling factor}

Similar to the @tech{segment duration scaling factor} transfer curve, you can specify that transition durations should be longer when the music is soft and shorter when the music is louder using, for instance -
@schemeblock[
(transition-duration-tc 0.00 2.00             
                        0.65 0.30
                        1.00 0.30)
]

If you want to specify cuts, you can use a value of 0.0. 

@defproc[(preferred-transition-duration (dur-secs number)) void]{
The value of the transition duration transfer curve is a scaling factor which is applied to the @scheme[preferred-transition-duration] setting.}

@defproc[(min-segment-duration-for-transition (dur-secs number)) void]{
Specifies a cut off duration below which you only get cuts. You can use this to introduce transitions only when you think the duration of segments is long enough for your transitions to make editing sense.}

@section{Time warping}

You get an emotionally appealing edit when you introduce slow motion video when the music is soft, speeding up to normal motion when the music activity picks up. You specify such behaviour using the @deftech{time warp transfer curve}. 

For example, the transfer curve -
@schemeblock[
(time-warp-tc 0.0 1/4
              0.5 1.0
              1.0 1.0)
]
will cause video to be played back in 4x slow motion when the music loudness is 0.0, gradually speeding up to normal speed (1.0) when the music loudness gets to 0.5 and staying at 1.0 for more energetic music levels. You can also specify values beyond 1.0 to cause video to play fast forward.

@section{Music descriptors}

Several descriptors are made available as normal muSE functions.

@scheme[(loudness _t)]
@indent{@scheme[loudness] is a function of time (expressed in seconds since the start of the muvee) and evaluates to the loudness of the mixed music at the given time. It will always yield a value in the range 0.0 to 1.0 and can therefore be used with the @scheme[with-descriptor] function (see @secref{About_effects_and_transitions}).}

@scheme[(cut-hint _t)] and @scheme[(flash-hint _t)]
@indent{Evaluates to a time-value pair @scheme[(_t . _v)] if a cut hint or a flash hint is present at the given time @scheme[_t], or to @scheme[()] if there's no such hint at the given time.}

@scheme[(cut-hints _t1 _t2)] and @scheme[(flash-hints _t1 _t2)]
@indent{These give you the respective hints as a list of @scheme[(_t . _v)] pairs where the times fall within the given interval @math{[t@subscript{1},t@subscript{2})}.}

@scheme[(cut-hint _t _pref-dur-beats)] and @scheme[(flash-hint _t _pref-dur-beats)]
@indent{These give you a cut or flash hint as a @scheme[(_t . _v)] pair that is somewhere around @scheme[(_t + (beats->secs _pref-dur-beats))] and has a maximal value @scheme[_v] among the hints near that time.}
               
@scheme[(set-additional-music-hints _hint-type _list-of-time-value-conses)] @New!{X}
@indent{A style can use this to provide additional hints about edit timing to the muvee engine. (The additional hints provided via this function do no affect the @scheme[cut-hints] and @scheme[flash-hints] functions. 

@scheme[hint-type] should either be @scheme['cut-hints] or @scheme['flash-hints]. The @scheme[list-of-time-value-conses] is a list in exactly the same format as the data returned by @scheme[cut-hints] and @scheme[flash-hints] functions. The "value" part of the time-value pairs is expected to be in the range 0 to 1, but it is not necessary for it to conform to that range though less than 0 would not be of much use. It can be greater than 1 though.}

