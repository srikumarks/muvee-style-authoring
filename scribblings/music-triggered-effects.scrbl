#lang scribble/doc
@(require scribble/manual)

@title{Music triggered effects}
Apart from setting parameters according to music characteristics in order
to make the effect music-responsive, you can trigger effects such as 
decaying flashes to occur at specific beat points in the music. 

The muvee music analyzer generates two types of @italic{hints} called
@italic{cut-hints} and @italic{flash-hints} which are expressed as sequences
of times with a @italic{strength value} attached to each time.
@itemize{
         @item{@bold{cut-hints} - Indicates suitable points for inserting 
                    a video ``cut'' that aligns with some significant event 
                    in the music. The strength value of a cut-hint (range 0.0 to 1.0) 
                    gives an indication of how loud the music event is.
                    Cut hints are based on events in the music with perceptible
                    ``attack'' and capture snare and base drum hits rather well.}
         @item{@bold{flash-hints} - These capture high spectral frequency 
                    events in the music such as hi-hats. The strength value of a
                    flash-hint indicates how loud the high frequency event is.
                    Flash-hints are called so because they are ideal times
                    for inserting decaying flashes in the result muvee.}
         }

@section{@scheme[triggered-effect]}
A triggered effect specification is created using the @scheme[triggered-effect]
form which is invoked as follows -
@schemeblock[(triggered-effect _start-time-expr _stop-time-expr _effect-expr)]

@scheme[triggered-effect] makes available a hint's time and value in the symbols
@scheme[time] and @scheme[value] in all the three parts of its body.

@itemize{
         @item{@scheme[_start-time-expr] is an expression that derives an effect 
                      start time from @scheme[time] and @scheme[value]. For 
                      example - @scheme[(- time 0.05)]}
         @item{@scheme[_stop-time-expr] is an expression that derives an effect
                      stop time from @scheme[time] and @scheme[value]. For example -
                      @scheme[(+ time 0.35)]}
         @item{@scheme[_effect-expr] is any effect specification expression. You can
                      use @scheme[(effect ....)] or a combined effect such as
                      @scheme[(effect-selector (looping-sequence ....))]. Additionally,
                      the body of this effect specification can refer to @scheme[time]
                      and @scheme[value] to derive any aspect of the effect.}
         }

You can turn a @scheme[triggered-effect] specification into a regular effect by
applying it to the various cut and flash hints in an interval. You do that using
one of the forms below -
@itemize{
         @item{@scheme[(effect@cut-hints _hints-per-min _min-sep-secs _trig-effect)]}
         @item{@scheme[(effect@flash-hints _hints-per-min _min-sep-secs _trig-effect)]}
         }
          
where -
@itemize{
         @item{@scheme[_hints-per-min] is the number of trigger points per minute
                      that you want the effect to be triggered on.}
         @item{@scheme[_min-sep-secs] is the minimum time-separation between two
                      consecutive trigger points.}
         @item{@scheme[_trig-effect] is a triggered effect created using @scheme[triggered-effect].}
         }
                    
