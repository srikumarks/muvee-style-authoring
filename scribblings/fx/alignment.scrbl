#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Alignment}

Aligns an edge of an image to a corresponding edge of the display area. It can also center the image. An image's alignment determines how it is presented when the aspect ratio of the output format changes. 

@effect-parameter-table[
                        [alignment 0 @math{{0,1,2,3,4}} @list{@itemize{
                                                                 @item{0: Center alignment}
                                                                 @item{1: Top alignment}
                                                                 @item{2: Bottom alignment}
                                                                 @item{3: Left alignment}
                                                                 @item{4: Right alignment}}}]
                        ]


@input-and-imageop[(A) "No"]

@section{Examples}

@subsection{Alignment example.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My good-looking style.")
(code:comment "This style demonstrates the Alignment effect.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
                                 (effect "Alignment" (A)
                                         (param "alignment" 2))                                
				 (effect "Perspective" (A))))
]




Aligning an image to the bottom of the display area:

@image["image/alignmentBottom.jpg"]




Unaligned image:

@image["image/alignmentNone.jpg"]








