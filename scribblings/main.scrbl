#lang scribble/doc
@(require scribble/manual scribble/struct scheme/date "utils.ss")

@title[#:style 'toc]{Authoring muvee Styles}

@bold{@secref{Getting_Started}}
@indent{Introduces the mechanics of creating a new style based on an existing one.}

@bold{@secref{Anatomy_of_a_muvee}}
@indent{Describes the structure of a typical muvee in terms of its parts. You
        need to know this as a style author before the rest of the documentation
        will make any sense.}

@bold{@secref{Tutorials}}
@indent{.... walk you through authoring muvee styles.}

@bold{@secref{Specifying_Style_Behaviour}}
@indent{Describes the contents of a style's @filepath{data.scm} file. This
        file defines everything that is unique about your style,
        so understanding how to edit this file is important.}

@bold{@secref{List_of_primitive_effects_and_transitions}}: @indent{Lists all the currently 
available primitive effects and transitions, describes what they do, what their 
parameters are, etc. A useful reference when authoring styles.}

@bold{@secref{A_Gentle_Introduction_to_muSE}}
@indent{Gets you Scheme-literate in a sprint. If you are familiar with 
        @link["http://plt-scheme.org"]{Scheme} or
        @link["http://muvee-symbolic-expressions.googlecode.com"]{muSE},
        you can skip this. It is more for those new to both.}

@subsubsub*section{Contents}

@local-table-of-contents[]
@include-section["license.scrbl"]
@include-section["getting-started.scrbl"]
@include-section["style-package-structure.scrbl"]
@include-section["anatomy-of-a-muvee.scrbl"]
@include-section["tutorials.scrbl"]
@include-section["specifying-style-behaviour.scrbl"]
@include-section["about-effects-and-transitions.scrbl"]
@include-section["sound-effects.scrbl"]
@include-section["fx/fx.scrbl"]
@include-section["showtime.scrbl"]
@include-section["misc.scrbl"]
@include-section["intro-to-muSE.scrbl"]
@index-section[]

@emph{Last updated: @(date->string (seconds->date (current-seconds)))}
