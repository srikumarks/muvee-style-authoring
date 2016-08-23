#lang scribble/doc
@(require scribble/manual)

@title{The @scheme[style-parameters] section}

A style can provide a range of behaviours by exposing some controls to
the muvee Reveal user. For example, a ``birthday party'' style can
provide a control for the number of balloons to use in the muvee. A
style describes its parameters in the @schemeblock[(style-parameters ....)] section
which should be the first section in the style's @tt{data.scm} file. 

If you're not exposing any parameters in your style, define an empty 
section right at the start of your @tt{data.scm} file, like so -
@schemeblock[(style-parameters)]

Here is an example capturing all the different types of parameters you
can expose in a style -
@schemeblock[
(style-parameters
    (code:comment #, @tt{@hspace[17]ParamName @hspace[2]Default @hspace[1]Min @hspace[4]Max})
    (continuous-slider SPEED       1.0      1.0     2.0)  
    (discrete-slider   BALLOONS    2        0       8)
    
    (code:comment #, @tt{CheckBox @hspace[1]ParamName @hspace[4]Default (on/off)})
    (switch     SHOW_CAPTIONS on)
    
    (code:comment #, @tt{ComboBox @hspace[2]ParamName @hspace[1]Default @hspace[6]ListOfValues})
    (one-of-many CAKE       WeddingCake   (WeddingCake BirthdayCake NewYearCake))
    
    (code:comment #, @tt{RadioButtons @hspace[1]ParamName @hspace[3]Default @hspace[4]ListOfValues})
    (one-of-few     CAPTION_POS  Bottom      (Top Middle Bottom))

    (code:comment #, @tt{ColorPicker @hspace[2]ParamName @hspace[6]Default (0x00RRGGBB)})
    (color          FADE_TO_COLOR   0x00FFFFFF)
    )
]

The value of any parameter can be accessed simply by using its name
wherever the currently set value is required. 

@section{@scheme[continuous-slider]}

@schemeblock[
    (code:comment #, @tt{@hspace[17]ParamName @hspace[2]Default @hspace[1]Min @hspace[4]Max})
    (continuous-slider SPEED       1.0      1.0     2.0)  
]
Specifies a continuous value in the given range. Note that the @italic{minimum} value
must be less than the @italic{maximum} value and the given default value must lie
within that range. Otherwise, muSE will pop up an error message.

The code above, when used as is, will create a slider named ``SPEED''
with the end points named ``SPEEDMIN'' and ``SPEEDMAX''. If you want to
change these strings, you can add the following entries in your
style's @tt{strings.txt} file -
@schemeblock[
SPEED	en-US	Speed
SPEED_MIN	en-US	Low
SPEED_MAX	en-US	High
]
With these strings in place, you'll see the slider end points named
@tt{Low} and @tt{High} instead of @tt{SPEEDMIN} and @tt{SPEEDMAX}. 

@section{@scheme[discrete-slider]}

@schemeblock[
    (code:comment #, @tt{@hspace[17]ParamName @hspace[2]Default @hspace[1]Min @hspace[4]Max})
    (discrete-slider   BALLOONS    2        0       8)
]

Similar to @scheme[continuous-slider]` above except that the values are integral.

@section{@scheme[switch]}
@schemeblock[
    (code:comment #, @tt{CheckBox @hspace[1]ParamName @hspace[4]Default (on/off)})
    (switch     SHOW_CAPTIONS on)
]

Defines a check-box kind of parameter - a parameter that can have
either @scheme[on] or @scheme[off] as its value. The display name can be specified
via the @tt{strings.txt} file just like @scheme[continuous-slider] above.

@section{@scheme[one-of-many] and @scheme[one-of-few]}
@schemeblock[
    (code:comment #, @tt{ComboBox @hspace[2]ParamName @hspace[1]Default @hspace[6]ListOfValues})
    (one-of-many CAKE       WeddingCake   (WeddingCake BirthdayCake NewYearCake))
    
    (code:comment #, @tt{RadioButtons @hspace[1]ParamName @hspace[3]Default @hspace[4]ListOfValues})
    (one-of-few     CAPTION_POS  Bottom      (Top Middle Bottom))
]

@scheme[one-of-many] creates a drop-down list of items that the user can
select from and @scheme[one-of-few] creates a set of radio buttons. Although
both are about selecting one item from a set, the name difference is
used as an indicator to the GUI about the control to display. 

You can do things in the style based on the @scheme[CAKE] parameter using a
branch expression such as -
@schemeblock[
(case CAKE
  ('WeddingCake ....)
  ('BirthdayCake ....)
  ('NewYearCake ....))
]

The parameters as specified above will cause the style to put up a
@scheme[CAKE] drop-down menu with the strings @scheme[WeddingCake], @scheme[BirthdayCake]
and @scheme[NewYearCake] as the menu entries. If you want to change the
display strings for these choices, you can add your preference to the
@tt{strings.txt} file as follows -
@schemeblock[
CAKE	en-US	Cake type
WeddingCake	en-US	A 3-storey wedding cake
BirthdayCake	en-US	Happy Birthday!
NewYearCake	en-US	Happy New Year!
] 

@section{@scheme[color]}
@schemeblock[
    (code:comment #, @tt{ColorPicker @hspace[2]ParamName @hspace[6]Default (0x00RRGGBB)})
    (color          FADE_TO_COLOR   0x00FFFFFF)
]

Defines a color selection parameter.  In the UI, this parameter should be displayed as a color swatch (i.e. rectangle showing the current color), which when clicked brings up the standard color picker control.

@section{Responding to style parameters}

Style parameters are just plain values - either numeric or symbolic. 
You can use the current settings of a style's parameters to compute
any aspect of the muvee. A parameter's symbol becomes automatically
defined to the current value of the style's control at the time a
muvee is made. 

For example, if you want the speed to be converted into a scaling
factor to apply to a duration value, you can write -
@schemeblock[
(define scaling-factor (/ 1.0 SPEED))
]
and use @scheme[scaling-factor] in any other computation. 