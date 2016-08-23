#lang scribble/doc
@(require scribble/manual)

@title{Primitive effects}

These are effects that are provided as part of the style authoring
framework and are used by name. For instance, the @scheme[Translate]
primitive effect can be used to shift the scene in 3D space by a
certain distance along a certain direction. 

Here is an example of what using the @scheme[Translate] effect to shift the
scene through half the screen width in the x direction looks like (coordinates
go from -1.0 to 1.0) - 
@schemeblock[
(effect "Translate" (A)
  (param "x" 1.0)
  (param "y" 0.0)
  (param "z" 0.0))
]

The basic use of a primitive effect has the structure -
@schemeblock[
(effect _name-string _input-pattern
  (param _pname-string _value)
  ....)
]

@section{Effect name}

Effects have simple string names such as @scheme["Translate"], @scheme["Rotate"] and
@scheme["Alpha"]. The names of effects are case-sensitive, so you @bold{cannot} use
@scheme["translate"] instead of @scheme["Translate"].

@section{Input pattern}

The @deftech{input pattern} is a list of symbols standing for the various inputs
that the effect is being applied on. 
@itemize{
  @item{Effects that don't take any input are specified using @scheme[()] as the input pattern.}
  @item{Effects that apply to one input such as segment effects and global effects are specified using the input pattern @scheme[(A)] (or any symbol in place of @scheme[A]).}
  @item{Transitions are nothing but two-input effects and therefore are specified using an effect pattern like @scheme[(A B)] (again, any symbols may be used in place of @scheme[A] and @scheme[B]).}
  }

The reason for the inclusion of the input pattern is that the body of
an effect can refer to the inputs by name if necessary.

@section{Parameter specification}
@schemeblock[
(param _pname-string ....)
]
The behaviour of most effects can be altered by setting values for one
or more of their parameters. Some effects even require certain
parameters to be set. 

Each @scheme[(param ....)] expression that appears within an @scheme[(effect
..)] expressions specify values for one of the effect's
parameters. Parameter names are also case-sensitive, just like
effect names.

@section{Types of values}

Values of type integer (@scheme[10], @scheme[5], etc.), fractional (@scheme[3.14], @scheme[2.718],
etc.) and string (@scheme["hello"], @scheme["olah"], etc.) are valid for use in the
value slot of a parameter specification. However, the types accepted
by a parameter are determined by the effect. For example, the
@scheme[Translate] effect's @scheme[x] parameter has to be a fractional (aka
floating point) value. It cannot be a string. The types of values
accepted by parameters are documented in the effect's documentation
page.

@section{File and directory values}

Some effects have parameters that accept file names. For example, the
PictureQuad effect's @scheme[File] parameter has to be set to the path to the
image file to display in the scene. 

Usually, a style will need to refer to images such a gradient maps in its data
folder and the @scheme[resource] function is available for this purpose.

@schemeblock[(resource "image.png")]

will expand to the full path to the @scheme["image.png"] file relative to
the style's data folder. 

Using the @scheme[resource] function, you can specify the @scheme[File] parameter of
an effect as follows -
@schemeblock[
(param "File" (resource "image.png"))
]

@section{Fixed parameters}

@schemeblock[(param "z" 0.5)]

It should be fairly obvious that the above expression specifies the
@scheme[z] parameter of an effect to the floating point value @scheme[0.5]. The
parameter @scheme[z] will take on this fixed value for the period that the
effect is being applied.

The value can also be a muSE expression that computes the @scheme[z]
coordinate. For example, if you have a @scheme[ZOOM] parameter that goes
from @scheme[0.0] to @scheme[1.0], you can compute the @scheme["z"] parameter from @scheme[ZOOM]
as follows -
@schemeblock[
(param "z" (+ 0.5 ZOOM))
]

Such an expression is computed only once and the value generated
by the expression will be used as the value of the parameter during
the entire time the effect is applied.

@section[#:tag "explicit-animation-curves" #:style 'quiet]{Explicit animation curves}

The values of parameters can change during the interval for which the
effect is applied. These are called ``animations''. For example, you can
@italic{animate} the @scheme[z] parameter of the @scheme[Translate] effect to cause the
user's media to zoom away to oblivion. For example -
@schemeblock[
(param "z" 0.0
    (linear 0.25 0.25)
    (linear 0.5 2.0)
    (linear 1.0 10.0))
]

The @scheme[(linear t val)] expression causes the parameter's value to change over
time to the given value. The above example describes a z-animation
according to the graph shown below -

@image["image/zt-linear.png"]

Only integer and fractional valued parameters can be animated using
@scheme[linear]. 

You can also cause a parameter to abruptly change value at set
times. To specify such a step-wise animation, you use @scheme[(at t val)] instead of
@scheme[linear]. Here's a variant of the @scheme[z] animation above -
@schemeblock[
(param "z" 0.0
    (at 0.25 0.25)
    (at 0.5 2.0)
    (linear 1.0 10.0))
]
which is described by the graph -

@image["image/zt-at.png"]

Therefore you can use combinations of @scheme[at] and @scheme[linear] to define
piece-wise linear animation curves.

@subsection{Time specification}

The time you give in @scheme[(linear t ..)] and @scheme[(at t ..)] expressions is
called @italic{progress time}. @scheme[0.0] refers to the start of the effect, @scheme[1.0]
refers to the end of the effect and @scheme[0.5] refers to ``half way through
the effect''. Although using @italic{progress time} (or @italic{progress} for short)
usually suffices for a broad range of animations, you occasionally
need to specify animation times in seconds.

For example, you might wish to write a ``fade out'' effect that fade
outs whatever it is applied to 0.5 seconds after the start of the
effect. You can use the @scheme[Alpha] primitive effect to implement such a
fade out, as shown below -
@schemeblock[
(effect "Alpha" (A)
  (param "Alpha" 1.0
    (at 0.5 1.0)
    (linear 1.0 0.0)))
]

.... but wait, we have not told the @scheme[at] setting to operate at 0.5
@italic{seconds}. We've told it to operate half way through the effect. In
order to do that we need to use the @scheme[effect-time] as follows.
@schemeblock[
(effect "Alpha" (A)
  (param "Alpha" 1.0
    (at (effect-time 0.5) 1.0)
    (linear 1.0 0.0)))
]

When we write it that way, we mean that the @scheme[0.5] is in @italic{seconds from
start of effect} and not progress. If you want to be very clear and
say that you really mean progres, you can write it as -
@schemeblock[
    (at (progress 0.5) 1.0)
]
The above form is useful when you're using an expression to compute
the animation time instead of directly putting in the number, as in -
@schemeblock[
   (at (progress (* 0.5 DELAY)) 1.0)
]

@scheme[progress] takes a progress value and converts it into absolute time
(in seconds) within the muvee. Similarly @scheme[effect-time] takes a time in
seconds relative to the start of the effect and converts it into
absolute time within the muvee. To convert between these, use the
following formulae -

@itemize{
         @item{@scheme[(progress p)] = @scheme[start] + @scheme[p] * (@scheme[stop] - @scheme[start])}
         @item{@scheme[(effect-time t)] = @scheme[start] + @scheme[t]}
         }

The words @scheme[start] and @scheme[stop] when used within the body of an @scheme[(effect
....)] expression refer to the start and stop time of the particular
instance of the effect for which the body is being
evaluated. Therefore you can use these words as values to convert
between any two time bases.

@section[#:tag "computed-param-animation"]{Computed animation curves}

Sometimes, it is convenient to specify an animation curve directly as
a function of time. For example, it is easy to express the free motion of a
ball in the vertical direction using the formula @tt{4ht*(1-t)}. This
formula evaluates to 0 for both t=0 and t=1 and reaches a maximum
height of @scheme[h] when t=0.5. For such cases, you can directly encode this
expression as a function and have muSE setup the animation for you as
follows -
@schemeblock[
(effect "Translate" (A)
  (param "y" 0.0 
  	 (fn (t) (* 4 h t (- 1 t)))))
]
Here we're giving a function of @italic{progress time} as the third
argument to the @scheme[param] expression. muSE will compute 8 values of this
function for every second of animation and setup a linear animation
just from that.

If you want to control how many intermediate values you want to
compute, you can specify that as the fourth argument to @scheme[param]. For
example, if you need to compute only 2 values per second, you can
write that as follows -
@schemeblock[
  (param "y" 0.0 
  	 (fn (t) (* 4 h t (- 1 t)))
	 2)
]
