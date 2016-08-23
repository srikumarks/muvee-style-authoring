#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{HeightMap}

Mutiplies a greyscale image with the input texture. You can use this to create an illusion of the texture being projected on an uneven surface.

@effect-parameter-table[
                        [Path "" @list{n/a} @list{The full path of the heightmap.}]
                        ]

@input-and-imageop[(A) "Yes."]


@section{Examples}

@subsection{Heightmap example.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My good-looking style.")
(code:comment "This style multiplies a greyscale image with the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-segment-effect (effect "HeightMap" (A)
                                     (param "Path" (resource "heightmap.jpg"))))

]


@image["image/heightMap.jpg"]


This is the original heightmap:


@image["image/heightMapOrig.jpg"]





