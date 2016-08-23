#lang scribble/doc
@(require scribble/manual "utils.ss")

@title{Combining effects}
The effect framework offers a few expressive ways to combine effects
to create new types of effects. The primitive effects can be kept
simple only if the means to combine them exists. This section is about
how to combine simple effects to create more sophisticated ones. It is
worth familiarizing yourself with @scheme[effect-stack] and @scheme[layers] because
you'll be using them a lot.

All these functions which transform one or a collection of effects 
into an effect are collectively referred to as @deftech{effect combinators}
and fall into the category of @deftech{higher order functions}.

@section{effect-stack}
Say you want to create a ``photo on the wall'' look for the pictures in
the muvee. You'll need to shrink down the picture a bit so the whole
thing fits into the screen and rotate it a bit to give the appearance
of casual placement on the wall. To create this look, you'll need to
combine the @scheme[Scale] and @scheme[Rotate] effects as follows -
@schemeblock[
(effect-stack
    (effect "Rotate" (A)
    	(param "degrees" 15.0))
    (effect "Scale" (A)
    	(param "x" 0.7)
	(param "y" 0.7)))
]

You can read an @scheme[effect-stack] expression from top to bottom.
@schemeblock[
(effect-stack
    (effect "Rotate" (A)
    	(param "degrees" 15.0))
    _rest-of-the-stuff)	
]
should be read as 

  @italic{The @scheme[_rest-of-the-stuff] is rotated by 15 degrees}.

Here is another way to write the same effect combination -
@schemeblock[
(effect-stack
    (effect "Rotate" (A)
    	(param "degrees" 15.0))
    (effect-stack
        (effect "Scale" (A)
    	    (param "x" 0.7)
	    (param "y" 0.7))))
]

i.e. the @scheme[_rest-of-the-stuff] can itself be seen as an effect stack.

@section{transition-stack}
Similar to @scheme[effect-stack] except that the last entry in the stack @bold{must}
be a transition - i.e. a two-input effect and the other @bold{must} be one-input
effects.

@section[#:style 'quiet]{layers}

The @scheme[layers] primitive combinator is the way to put together a scene
in parts. For example, you might want to present a single picture with
four different colorations, Andy Warhol style. @scheme[layers] will help you
compose such compound scenes.

A @scheme[layers] composition has the following form -
@schemeblock[
(layers _input-pattern
	_effect1
	_effect2
	....
	_effectN)
]

The @scheme[_input-pattern] has the same form and purpose as the 
@tech{input pattern} specification for effects. The most
important point to note here is that @scheme[_effect1], @scheme[_effect2] etc. @bold{must}
be zero-input effects. We will use the term @italic{layer} to refer to
@italic{zero-input effects} hereafter.

@subsection{An example}
Say we want to place four space-shifted copies of a picture or video with 
decreasing transparencies to create a motion-blurred appearance.

We can write down our intention like this -
@schemeblock[
(layers (A)
  (code:comment #, @tt{                    input  x-shift  opacity})
  (shifted-translucent   A      0.0     0.6)
  (shifted-translucent   A      0.2     0.4)
  (shifted-translucent   A      0.4     0.2)
  (shifted-translucent   A      0.6     0.1))
]
where we expect the @scheme[shifted-translucent] function to somehow compute
a zero-input effect specification that operates on the layer's single
input @scheme[A]. Knowing what we expect this function to do, we can proceed
to elaborate it -
@schemeblock[
(define (shifted-translucent A x-shift opacity)
  (effect-stack
    (effect "Alpha" (Shifted)
      (param "Alpha" opacity))
    (effect "Translate" (Scaled)
      (param "x" x-shift))
    (effect "Scale" ()
      (input 0 A)        (code:comment #, @tt{'A' comes from function parameter})
      (param "x" 0.4)
      (param "y" 0.4))))
]

Here is what the composition looks like -

@image["image/motion-blur.jpg"]

@subsection{Explicit inputs}

@schemeblock[
(input _index _the-input)
]

Knowing that the @scheme[shifted-translucent] function should compute a
zero-input effect tells us that the last entry of the @scheme[effect-stack]
that we use must be a zero-input effect as well.

The @scheme[Scale] effect is normally a one-input effect. We therefore turn
it into a layer for the above example by explicitly specifying its
input as what was given to the @scheme[make-shifted-translucent] function as
its @scheme[A] parameter. We do that using the @scheme[input] form which has the
following general structure -

The inputs to an effect are numbered from 0. Therefore @scheme[0] for
@scheme[_index] means the first input, @scheme[1] means the second input, etc.

The ability to explicitly specify inputs is essential to many kinds of
layer compositions such as what we did above.

@section{remap-time}

@defproc[(remap-time (fstart fraction) (fstop fraction) (fx effect)) effect]{

@scheme[remap-time] doesn't combine effects, but it transforms one effect into 
another that operates for only a part of the full span of an effect. For example,
you might want to author a segment effect, but want it to operate only
for the middle 1/3 of the segment. You can restrict the time interval for such
purposes using @scheme[remap-time]. For example -

@schemeblock[
(define muvee-segment-effect 
  (remap-time 1/3 2/3 (effect "Sepia" (A))))
]

- gives you a segment effect that operates for only the middle 1/3 of a segment.

@scheme[_fstart] and @scheme[_fstop] are fractional values indicating the fraction
of the full interval @math{[start, stop)} for which the effect should apply. 
@indent{@scheme[_fstart] is in the range @math{[0.0, fstop)} and}
@indent{@scheme[_fstop] is in the range @math{(fstart, 1.0]}.}

@scheme[remap-time] doesn't combine two or more effects, but is useful when combining
two or more effects using, say, @scheme[layers]. 

}



