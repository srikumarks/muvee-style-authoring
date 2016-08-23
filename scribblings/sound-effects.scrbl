#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{Sound effects}

You specify sound effects within an @scheme[(effect ....)] expression using the @schemeblock[(sound ....)] form. Here is a sample sound effect specification - 
@schemeblock[
(effect .... 
    (sound  "sfx/000-funny-sound-2.04.mp3" 
            time-scale: (smpte 7.10)
            start: (smpte 4.01)
            mstop: (smpte 2.04)
            volume: (dB -6)))
]

The @scheme[sound] function gets values from its argument list using a keyword-based approach because in this case there are too many values for visual comfort while reading the specification. 

Notice that the @scheme[sound] form can only be specified within an @scheme[(effect ....)] expression. This means it has to be explicitly related to some part of the muvee such as a @emph{segment} or a @emph{transition}. You can also specify sound effects globally within any @emph{global effect}. The reason for this association is that sound effects are generally placed relative to significant points in the music and effect placement automatically gives you access to these significant point. Also, since effects are time limited, the @scheme[sound] specified within an effect is also automatically time limited (or not) depending on the parameters that were provided.

@section{@scheme[(sound ....)] syntax}

The syntax of the @scheme[sound] function is as follows -

@schemeblock[
(sound _relative-path-to-file keyword1: _value1 keyword2: _value2 ...)
]

The @scheme[_relative-path-to-file] is a string giving a path to an mp3 file relative to the style's package folder. All keyword-value pairs are optional and have default behaviour when unspecified. Note that keywords have a ``@scheme[:]'' character as suffix to distinguish them from normal symbols.

The following keywords are available -

@scheme[time-scale:] @indent{The value relative to which playback times are specified. Defaults to 1.0.}
@scheme[start:] @indent{The relative time (w.r.t. time-scale) at which to start playing the sound. Defaults to start of effect - i.e. 0.0.}
@scheme[stop:] @indent{The relative time at which to stop playing the sound. To let it play for as long as it can, omit this parameter. If you omit it, you @bold{must} specify the @scheme[mstop:] parameter.}
@scheme[fade-in:] @indent{The relative time for which the sound must fade in after start of play. Defaults to 0.0.}
@scheme[fade-out:] @indent{The relative time for which the sound must fade out before end of play. Defaults to 0.0.}
@scheme[mstart:] @indent{The position (in seconds) within the sound file from which to start playback. Defaults to start of sound file - i.e. 0.0 seconds.}
@scheme[mstop:] @indent{The position (in seconds) within the sound file until which to play. If you want to stop at a time determined by the @scheme[stop:] keyword, then don't specify this value. If you don't specify this, then you @bold{must} have specified @scheme[stop:].}
@scheme[pitch:] @indent{A pitch correction value for adjusting the sound's playback speed. The correction value is given in octaves, so that 0.0 means ``no change'', 1.0 means ``double the speed'' and -1.0 means ``half the speed''. Defaults to 0.0.}
@scheme[volume:] @indent{A volume adjustment factor. It specifies a multiplier for the amplitude of the sound clip. Defaults to 1.0.}

@section{Unit helper functions}

@defproc[(smpte (t SMPTE-time)) time-in-seconds]{
Used to convert a smpte time specification into seconds. For example, @scheme[(smpte 4.15)] stands for the absolute time ``4.5 seconds''. Here's how the ``4.15'' is converted to ``4.5'' - @scheme[4 + (0.15 / 0.30)].}

@defproc[(dB (level number)) fraction]{Used to convert a dB value to a multiplication factor. @scheme[(dB -3.0)] will give you 0.5.}
@defproc[(semitones (s number-in-semitones)) number-in-octaves]{Used to convert a semitone value to octaves. @scheme[(semitones 2)] will give you 2/12. If you don't mind the explicit 12, you can directly use the constant fraction expression @scheme[2/12] instead of @scheme[(semitones 2)].}
