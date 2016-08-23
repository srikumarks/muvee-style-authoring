#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{Descriptor matching}

A style can indicate default preferences for the kind of material that will suit it best. The user can override the style default by going into the media selection settings panel (@onscreen{Personalize} -> @onscreen{Durations} -> @onscreen{Details} -> @onscreen{more}). That option is set to @emph{Style preference} by default. A style author uses the following functions to specify the default media selection preference for her style.

@scheme[(face-bias _bias)]
@indent{The style preferred bias towards faces is set to the given @scheme[_bias] value. The bias can take a value in the range -1.0 to 1.0. Positive values indicate a preference for faces and negative values indicate a preference against faces. 0.0 pretty much means ``I don't care about faces''. When not set, it defaults to 0.0.}

@scheme[(motion-preference _bias _target)]
@indent{A style indicates a preference for material with a particular value of the motion descriptor - the @scheme[_target] - which can take a value in the range 0.0 (meaning low motion or activity) to 1.0 (meaning high motion or activity). The strength of the preference is indicated by the @scheme[_bias] value which can take any value in the range 0.0 to 1.0.  Higher values of the bias indicate a stronger preference for content with the given motion target value. When not set, the bias value is 0.0 and target is 1.0.}

@scheme[(brightness-preference _bias _target)]
@indent{Similar to @scheme[motion-preference] but applies to the brightness descriptor. The ranges and meaning of @scheme[_bias] and @scheme[_target] parameters is also the same as @scheme[motion-bias]. When not set, the bias is 0.0 and target is 1.0.}