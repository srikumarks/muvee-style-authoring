#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title[#:style 'toc]{Specifying Style Behaviour}

Every style package has a file named @filepath{data.scm} that defines everything
that is unique about the style. Its contents specify -
@itemize{
         @item{How the title part should be constructed.}
         @item{How the credits part should be constructed.}
         @item{How the muvee body should respond to the music track.}
         @item{How each segment of the muvee body should look and sound like.}
         @item{How a muvee made by the style should look like overall.}
         @item{How each segment in the muvee body leads into the one following it.}
         @item{How to create style controls that the user can tweak.}
         }
This section is all about what goes into a style's @filepath{data.scm} file.
A typical data.scm file looks like this -

@schemeblock[
(code:comment "muSE v2")

(code:comment "---------------------")
(code:comment "Parameters exposed via 'Style Settings'")
(#,(seclink "The_style-parameters_section" (scheme style-parameters)) ....) 

(code:comment "---------------------")
(code:comment "Music response specification")
(#,(seclink "Segment_duration_pattern" (scheme segment-durations)) ....)
(#,(seclink "Segment_duration_scaling_factor" (scheme segment-duration-tc)) ....)
(#,(seclink "Transition_duration_scaling_factor" (scheme transition-duration-tc)) ....)
(#,(seclink "Time_warping" (scheme time-warp-tc)) ....)

(code:comment "---------------------")
(code:comment "Manipulating input shots prior to construction")
(define #,(seclink "The_shot_vector_transform" (scheme muvee-shot-vector-transform)) ....)

(code:comment "---------------------")
(code:comment "Various definitions for effects and transitions.")
(code:comment "...")

(code:comment "The effect to apply to each segment.")
(define #,(seclink "The_segment_effect" (scheme muvee-segment-effect)) ....)

(code:comment "The treatment to apply to the entire muvee.")
(define #,(seclink "The_global_effect" (scheme muvee-global-effect)) ....) 

(code:comment "The transition to use to move from one segment to the next.")
(define #,(seclink "The_transition" (scheme muvee-transition)) ....)

(code:comment "---------------------")
(code:comment "Title and credits specifications.")
(#,(seclink "Title_and_Credits" (scheme title-section)) ....) 
(#,(seclink "Title_and_Credits" (scheme credits-section)) ....) 
]

@subsubsub*section{Contents}
@local-table-of-contents[]

@include-section["muse.scrbl"]
@include-section["style-parameters.scrbl"]
@include-section["title-and-credits-sections.scrbl"]
@include-section["music-response.scrbl"]
@include-section["descriptor-matching.scrbl"]
@include-section["shot-vector-transform.scrbl"]


@section{Miscellany}

@subsubsub*section{@scheme[(disable-default-kenburns)]}
@indent{Use this to disable the default panning/zooming behaviour for your style. You might want to
throw in your own implementation just so you don't surprise the user by not responding to their
pan/zoom animation settings.}

@subsubsub*section{@scheme[muvee-duration-secs]}
@indent{Within an @scheme[(effect ....)], this symbol gives you the total duration of the muvee in seconds.
Sometime useful to decide the timing of music triggered effects.}

