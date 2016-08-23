#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Material}

This effect should be used along with the @secref["Light"] effect. After you have set you light properties, you are expected to set your @scheme["Material"] properties as well. As with a light source. A material has a @scheme[Specular], @scheme[Emissive] (ambient) and @scheme[Diffuse] property. 

Please refer to the Light effect or the @link["http://www.glprogramming.com/red/chapter05.html"]{Blue Book Chapter 5} for more information.            
 
                       
@effect-parameter-table[

[MatColorR 1.0 @math{[0.0,1.0]} @scheme[The red   component of the material color] ]
[MatColorG 1.0 @math{[0.0,1.0]} @scheme[The blue  component of the material color] ]
[MatColorB 1.0 @math{[0.0,1.0]} @scheme[The green component of the material color] ]                        
                        
[MatEmissionR 0.0 @math{[0.0,1.0]} @scheme[The red   component of the material emission] ]
[MatEmissionG 0.0 @math{[0.0,1.0]} @scheme[The blue  component of the material emission] ]
[MatEmissionB 0.0 @math{[0.0,1.0]} @scheme[The green component of the material emission] ]

[MatDiffuseR 1.0 @math{[0.0,1.0]} @scheme[The red   component of the material diffusion] ]
[MatDiffuseG 1.0 @math{[0.0,1.0]} @scheme[The blue  component of the material diffusion] ]
[MatDiffuseB 1.0 @math{[0.0,1.0]} @scheme[The green component of the material diffusion] ]

[MatSpecularR 0.0 @math{[0.0,1.0]} @scheme[The red   component of the material specularity] ]
[MatSpecularG 0.0 @math{[0.0,1.0]} @scheme[The blue  component of the material specularity] ]
[MatSpecularB 0.0 @math{[0.0,1.0]} @scheme[The green component of the material specularity] ]

[MatShininess 10 @math{[0.0,128.0]} @scheme[The shininess of our texture]]

[ComputeSurface 1 @math{{0,1}}  @list{Set to @scheme[1] if you want to break down the surface into a quad grid so that lighting effects are smoother. If another effect down the effect stack is doing this for you, then you can set this to @scheme[0].}]
]

@input-and-imageop[(A) @list{If @scheme[ComputeSurface] is set to @scheme[1]}]

@section{Examples}

@subsection{Simple material example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "My yellowish style")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect (effect-stack
                              (effect "Light" (A))
                              (effect "Material" (A)
                                      (param "MatColorB" 0.0))))
]

In this simple example, the material will not absorb any blue color. What that implies is that we end up with a yellow-ish looking muvee.


@image["image/material.jpg"]


@subsection{Searchlight style with only diffuse color.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "Searchlight2. The return!")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect (effect-stack
                              (effect "Light" (A)
                                      (param "LightDiffuseR" 1.0)
                                      (param "LightDiffuseG" 1.0)
                                      (param "LightDiffuseB" 1.0)
                                      (param "DefaultMaterialColor" 0))
                              (effect "Material" (A)
                                      (param "MatColorR" 0.0)
                                      (param "MatColorG" 0.0)
                                      (param "MatColorB" 0.0))))
]

The above example is *almost* the same as the one we showed in the @secref["Light"] effect. Except that this time, the material only absorbs @scheme[Diffuse] light as its @scheme[emissive] and color are set to zero. As can be seen, we have a really circular search light.


@image["image/material2.jpg"]
