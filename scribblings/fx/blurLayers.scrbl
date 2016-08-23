#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{BlurLayers}

Blurs images using a higher quality technique than the @secref{Blur} effect. Images are blurred by superimposing layers of lower-resolution translucent copies on the original.

@effect-parameter-table[
[NumberOfLayers 7 @math{> 0} @list{The number of layers of the input image to superimpose.}]

[LayerOffset 0.03 @math{> 0.0} @list{The offset between the layers. The offset is randomized a bit.}]

[LayerAlpha 0.2 @math{( 0.0 - 1.0 )} @list{The opacity of the Layers. Note that Layer0 always has an alpha of 1.0. All subsequent layers will have an alpha specified by this parameter.}]

[LevelOfDetail 4.5 @math{>= 0.0} @list{The amount of blur to apply to the layers other than the original image.}]
]

@input-and-imageop[(A) "No"]

@section{A fancier blur}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super blurry style.")
(code:comment "   This style blurs the user image.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-segment-effect (effect "BlurLayers" (A)
                                     (param "NumberOfLayers" 4)))
]

. 

@image["image/blurLayers.jpg"]





