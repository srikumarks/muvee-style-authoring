#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{CrossFade}

It is a transition that fades out its first input while fading in its second, over the course of the transition. The fades are achieved by animating the scene opacity similar to the way the @secref{Alpha} works.

@effect-parameter-table[]

@input-and-imageop[(A B) "No"]

@section{Equivalent muSE code}

The cross fade can be implemented entirely in muSE using @secref{Alpha} and @secref{layers} as follows -
@schemeblock[
(define cross-fade
  (layers (A B)
          (effect "Alpha" ()
                  (input 0 A)
                  (param "Alpha" 1.0 (linear 1.0 0.0)))
          (effect "Alpha" ()
                  (input 0 B)
                  (param "Alpha" 0.0 (linear 1.0 1.0)))))
]

@section{Usage and issues}

A cross fade between two images is useful when there are parts of the two images that do not overlap in a presentation. If both images span the entire display area, you should use the @scheme["Dissolve"] effect instead, which does not animate the opacity of its first input. The @scheme[CrossFade] effect in such a situation creates a dip in the overall luminosity of the output since it is animating the opacity of both its inputs.

@section{Simple CrossFade transition}

If we are doing a transition between two pictures, the first picture will slowly disappear and the second picture will slowly fade-in and appear.


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   This style showcases the CrossFade transition where input A dissolves to reveal input B.")

(style-parameters)

(segment-durations 8.0)

(define muvee-transition (effect "CrossFade" (A B)))		

]

@image["image/crossfade.jpg"]
