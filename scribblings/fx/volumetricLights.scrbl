#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{VolumetricLights}

Applies a directional glow to the images in the scene. 

@effect-parameter-table[
                        [BlendMode 1 @math{{0,1,2,3}} @list{@itemize{
                                                                     @item{ @scheme[0]: @scheme[BlendMode_Luminance] - @t{The image LUMINANCE is blended to create the volumetric lights} }
                                                                     @item{ @scheme[1]: @scheme[BlendMode_RGBA] - The image RGBA pixels are blended to create the volumetric lights }
                                                                     @item{ @scheme[2]: @scheme[BlendMode_Intensity] - The image INTENSITY is blended to create the volumetric lights }
                                                                     @item{ @scheme[3]: @scheme[BlendMode_Alpha] - The image ALPHA is blended to create the volumetric lights }}}]
                        [NumberOfLayers 5 @math{> 0} @list{To create volumetric lights, we first take image A and create a pyramid of layers of image A. In other words, if image A has width and height of 1.0, the layer above it will have a width and height of, say, 0.9 and the layer of top of the first layer will have a width and height of 0.8 and so on. This parameter lets the effect know how many such layers do we want.}]
                        [TextureIncrement 0.05 @math{> 0} @list{This parameter lets the effect know by how much we want to change the width and height of subsequent layers along the pyramid, in other words, how steep we want our image pyramid to be.}]
                        [Quality 2 @math{{0,1,2,3}}  @list{@itemize{
                                                                      @item{@scheme[0]: @scheme[Quality_Lowest]}
                                                                      @item{@scheme[1]: @scheme[Quality_Lower]}
                                                                      @item{@scheme[2]: @scheme[Quality_Normal]}
                                                                      @item{@scheme[3]: @scheme[Quality_Higher]}}}]
                        [TranslateIncrement 0.03 @math{0.03} @list{The image pyramid is created at the same z-axis value. We use this parameter to space out different layers.}]
                        
                        [Alpha -1.0 @math{[0.0,1.0]} @list{If this parameter is not set, i.e. has a value of -1.0, the effect will calculate the start alpha of layer0 based on the total number of layers. However it is possible for the style author to set the alpha of the volumetric light. A low value will create a very subtle volumetric light. A high value for alpha will create a very strong volumetric light.}]
                        
                        [AlphaDecay 0.99 @math{[0.0,1.0]} @list{ We want the alpha of each layer to fade out as we progress up the pyramid. If the base layer has an alpha of X, layer 1 will have an alpha of 0.99 * X and layer 2 will have an alpha of 0.99 * 0.99 * X and so on.}]
                        
                        [Mode 0 @math{{0,1}} @list{@itemize{
                                                                      @item{@scheme[0]: @scheme[Mode_Perspective] - perform volumetric lighting in perspective view hence creating a sense of depth.}
                                                                      @item{@scheme[1: @scheme[Mode_Orthogonal] - perform volumetric lighting in orthogonal view hence removing all sense of depth.]}}}]
                        
                        [Animation -1.0 @math{[0.0,1.0]} @list{If this parameter is not set, i.e. has a value of -1.0, then the volumetric light will follow the animation of a sine curve from 0 to pi and back to 0. However if the style author wishes to have a custom animation of the volumetric light, then this parameter should be set. By animation, we mean the way the image starts out as a normal image and half-way along the muvee segment, the image is in full volumetric lights and then dies off to return to the original image.}]
                                        

                        ]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Creating a nice halo-like volumetric light effect.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super glowy style.")
(code:comment "   This style creates a Volumetric light effect on top of the user image.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))
                                 (effect "Translate" (A)
                                         (param "z" -1.0))))

(define muvee-segment-effect (effect "VolumetricLights" (A)
                                     (param "NumberOfLayers" 10)
                                     (param "TextureIncrement" 0.01)))
]

We move the image by @scheme[-1.0] in the z-space to fully appreciate the volumetric lights. I have also increased the @scheme[NumberOfLayers] and decreased the @scheme[TextureIncrement] to make the glow smoother. Do note that increasing the number of layers will slow down your system. 

@image["image/volumetricLights.jpg"]





