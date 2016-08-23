#lang scribble/doc
@(require scribble/manual)

@title{Variable effects}
The value of an effect's parameter can vary over the effect's interval by
specifying @seclink["explicit-animation-curves"]{explicit} or  
@seclink["computed-param-animation"]{computed} animations. Beyond that,
you can control how the various instances of an effect specification
differ from each other. This variation technique is indispensable if you
want to sustain the interest of your viewers.

Here are a few ways in which you can infuse such variety in your
productions.

@section{Using computed parameter values}

Any expression you use to specify the value of an effect's parameter is
computed once per effect instance. This gives you an opportunity to vary
the value of a parameter between the instances. The simplest such variation
is to set the value of a parameter to a random number in a given range.
You can, for example, set a random translation value for the @scheme[Translate]
effect's @scheme[x] parameter as follows -

@schemeblock[
(effect "Translate" (A)
        (param "x" (rand 0.3 0.5)))
]

If the above effect is used as a @scheme[muvee-segment-effect], you'll
find each segment of the muvee space shifted by a different amount.

You can use any expression that will evaluate to different values
every time it is evaluated in order to generate variations in the
value of a parameter.

@section{Using sequences}

The style authoring library comes with three functions for creating
sequences of things. These are -
@itemize{
         @item{@scheme[(looping-sequence _e1 _e2 ....)]}
         @item{@scheme[(random-sequence _e1 _e2 ....)]}
         @item{@scheme[(shuffled-sequence _e1 _e2 ....)]}
         }
They all give you a function that should called with no arguments. 
These functions return different values every time they are called.
The @scheme[_e1], @scheme[_e2], etc. can be any kind of muSE object.

Here is a trivial example -
@schemeblock[
(define beat (looping-sequence 1 2 3 4))
(beat) (code:comment #, @t{will give you 1})
(beat) (code:comment #, @t{will give you 2})
(beat) (code:comment #, @t{will give you 3})
(beat) (code:comment #, @t{will give you 4})
(beat) (code:comment #, @t{will give you 1})
(beat) (code:comment #, @t{will give you 2})
(code:comment #, @t{.... and so on.})
]

The @scheme[random-sequence] form yields a function that might return
any one of the values when it is invoked, with equal probability. The
@scheme[shuffled-sequence] is similar, but ensures that each item is
used once before repeating them.

You can use the generated @italic{sequence functions} to set the parameters
in effect specifications. For example, the definitions -
@schemeblock[
(define left-to-right (looping-sequence -0.4 -0.1 0.2 0.5))
(define muvee-segment-effect
  (effect "Translate" (A)
          (param "x" (left-to-right))))
]
will give you a looping left to right shift from segment to segment over
the course of the muvee. This assumes that effects for segments are 
calculated starting from the first segment at the start of the muvee
and proceeding to subsequent segments one by one, which is guaranteed.

@section{Using @scheme[effect-selector]}
Check this out -
@schemeblock[
(define muvee-segment-effect
  (effect-selector (random-sequence (effect "Translate" (A)
                                            (param "x" 0.2))
                                    (effect "Rotate" (A)
                                            (param "degrees" 30.0))
                                    (effect "Scale" (A)
                                            (param "x" 1.5)))))
]
will use one of the three effects - @scheme[Translate], @scheme[Rotate] 
and @scheme[Scale] - for each segment of the muvee, randomly.

Yes, you can really put anything into a @scheme[looping/random/shuffled-sequence], 
including effect specifications.
                                     
@section{Responding to music descriptors}

You can animate effect parameters based on what is happening in the music.
The @scheme[(loudness t)] function, for example, tells you how loud the 
music is at the given time @scheme[t], as a number in the range 0.0 to 1.0.

Here is a scale effect which continuously scales its input depending on
the loudness -
@schemeblock[
(effect "Scale" (A)
        (param "y" 1.0 
               (fn (p) (+ 1.0 (loudness (progress p))))
               2))
]

See @secref["computed-param-animation"] for explanation.

A more advanced technique is to select effects based on descriptor
values, i.e. you pick from a different set of effects depending on the
mood of the music. You can therefore choose to use one set for
soft parts of the music and another for the more energetic parts.

We use the term @italic{@as-index{transfer curve}} to mean a function from
a numeric value, usually in the range 0.0 to 1.0, to some other
value, which could be numeric as well. We can create a function
that selects an effect based on the value of a numeric parameters
as follows -
@schemeblock[
(define picker (step-tc 0.0 effect1
                        0.3 effect2
                        0.6 effect3))
]
With that definition, @scheme[(picker 0.2)] will give you
@scheme[effect1], @scheme[(picker 0.4)] will give you @scheme[effect2],
and @scheme[(picker 0.9)] will give you @scheme[effect3], and ...
you get the point.

Now we can use the @scheme[loudness] function to select one of the
three effects via the @scheme[picker] function as follows -
@scheme[(picker (loudness t))]. We still need to turn it into
an effect since we don't know what @scheme[t] is. We'll know that
only at the time the effect gets instantiated.

The @scheme[with-descriptor] form takes a function like @scheme[picker]
and a descriptor function like @scheme[loudness] (any function of time)
and yields a ``selector'' function like @scheme[looping-sequence]. Therefore
you can use the result of the @scheme[with-descriptor] form with
@scheme[effect-selector] to get an effect that responds to music
by selecting an appropriate effect.
@schemeblock[
(effect-selector (with-descriptor loudness
                                  (step-tc 0.0 effect1
                                           0.3 effect2
                                           0.6 effect3)))
]

@section{Using special conditionals}
You can apply different effects depending on whether the thing being
applied to is an image or a video.
@itemize{
         @item{@scheme[(if-image _image-effect _video-effect)] : Behaves like 
                      @scheme[_image-effect] if it is applied to an image and like 
                      @scheme[_video-effect] if it is applied to video.}
         @item{@scheme[(if-video _video-effect _image-effect)] : The inverse of 
                      @scheme[if-image].}
         @item{@scheme[(if-portrait-image _portrait-effect _other-effect)] : Special treatment
                      for portrait images.}
         @item{@scheme[(if-landscape-image _landscape-effect _other-effect)] : Special treatment
                      for landscape images.}
         }
You can combine the combinators themselves. For example, 
@schemeblock[(if-portrait-image _special (if-image _generic-image _for-video))] is a valid effect.
You can also combine these with @scheme[effect-stack], @scheme[layers] and such, for example -
@schemeblock[
(effect-stack
 (if-portrait-image portfx1 (if-video vfx2 blank))
 grainy-gray)
]

@section{Controlling effects with style parameters}

If your style has a @scheme[PARTY_WILDNESS] parameter that the user can control,
you can use it to select appropriate effects and vary the selection over the course
of the muvee. The possibilities of combinations are endless. As an exercise, figure out
what the following effect might do, assuming @scheme[PARTY_WILDNESS] takes values in the 
range @scheme[0.0] to @scheme[1.0] -
@schemeblock[
(effect-selector 
 (with-descriptor 
  (fn (time) (math PARTY_WILDNESS * (time / muvee-duration-secs)))
  party-effects))
]
