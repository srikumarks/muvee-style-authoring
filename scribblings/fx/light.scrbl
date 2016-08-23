#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Light}

Sets up a light source for your scene, overriding the default white-light that is applied. You can setup tinted ambient lights, spot lights, and such using this effect.

Light is divided into three components. @bold{Ambient} Light, @bold{Specular} light and @bold{Diffuse} light.
            @itemize{
                     @item{ @bold{Ambient} light can be defined as the background light. One good example is a room with the curtains pulled.} 
                     @item{@bold{Diffuse} light can be defined as light coming on one specific direction. One good example is a lamp. Most of the light is seen to come from the bulb.}
                     @item{@bold{Specular} light can be defined as concentrated light. It has one specific source (like a lamp) with the additional condition that it is reflected off surfaces in one particular direction.}}
            
Please refer to the @link["http://www.glprogramming.com/red/chapter05.html"]{Blue Book Chapter 5} for more information.            
 
                       
@effect-parameter-table[
[LightNumber 0 @scheme[0 to 13] 
      @list{The light number. You can have a maximum of 13 different lights at any given time operating simulteanously}]

[LightAmbientR 1.0 @math{ (0.0 - 1.0) } @list{The red   component of the ambient light}]
[LightAmbientG 1.0 @math{ (0.0 - 1.0) } @list{The blue  component of the ambient light}]
[LightAmbientB 1.0 @math{ (0.0 - 1.0) } @list{The green component of the ambient light}]

[LightDiffuseR 0.0 @math{ (0.0 - 1.0) } @list{The red   component of the diffuse light}]
[LightDiffuseG 0.0 @math{ (0.0 - 1.0) } @list{The blue  component of the diffuse light}]
[LightDiffuseB 0.0 @math{ (0.0 - 1.0) } @list{The green component of the diffuse light}]

[LightSpecularR 0.0 @math{ (0.0 - 1.0) } @list{The red   component of the specular light}]
[LightSpecularG 0.0 @math{ (0.0 - 1.0) } @list{The blue  component of the specular light}]
[LightSpecularB 0.0 @math{ (0.0 - 1.0) } @list{The green component of the specular light}]

[PositionDirection 1.0 @math{ (0.0,1.0) } @list{
                                     @itemize{
                                               @item{@scheme[0]: LightX, LightY and LightZ refer to the direction of the light}
                                               @item{@scheme[1]: LightX, LightY and LightZ refer to the position of the light}}}]

[LightX 0.0 @list{n/a} @list{The x position or direction of the light} ]
[LightY 0.0 @list{n/a} @list{The y position or direction of the light} ]
[LightZ 3.0 @list{n/a} @list{The z position or direction of the light} ]

[SpotDirectionX 0.0 @list{n/a} @list{The x direction of the light. SpotDirectionX,Y,Z are used when PositionDirection is set to 0.0} ]
[SpotDirectionY 0.0 @list{n/a} @list{The y direction of the light} ]
[SpotDirectionZ -1.0 @list{n/a} @list{The z direction of the light} ]

[SpotConstantAttenuation 1.0 @list{n/a} @list{The rate at which the light dies out, this value is added to SpotLinearAttenuation}]
[SpotLinearAttenuation 0.0 @list{n/a} @list{The rate at which the light dies out with respect to distance}]
[SpotCutOff 90.0 @math{0.0 - 180.0} @list{The field-of-view in angles of the spotlight}]
[SpotFlicker 0.0 @math{>= 0.0} @list{The range within which we allow the SpotExponent to randomly vary,  For example, if the SpotExponent is 60.0 and the SpotFlicker is 1.0, then the SpotExponent will randomly vary with the range ( 59.0 - 61.0 ), This parameter is useful if we want to create an OldMovie type flickering effect of the light}]
[DefaultMaterialColor 1 @math{{0,1}} @list{0 means we paint the material with calls to glColor, 1 means we paint the material using the "Material" effect}]

]


@input-and-imageop[(A) "No."]

@section{Examples}

@subsection{Simple searchlight example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "My Searchlight style")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect (effect-stack
                              (effect "Light" (A)
                                      (param "SpotDirectionX" -0.5 (linear 0.5  0.5)
                                                                   (linear 1.0 -0.5)))
                              (effect "Material" (A))))
]

This style uses an @seclink["effect-stack"]{effect-stack}. The above style creates a search light that moves across the screen from left to right. Do note that we also include the material effect in the example. This effect just breaks up our image into a small grid and sets some additional image surface parameters to make the effect work well.

@image["image/light.jpg"]



@subsection{Multiple lights example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "My super colorful style")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect (effect-stack
					(effect "Light" (A)
						(param "LightNumber" 4))
					(effect "Light" (A)
						(param "LightNumber" 3)
						(param "LightAmbientB" 0.0)
						(param "LightAmbientG" 0.0)
						(param "SpotDirectionX"  0.0 )
						(param "SpotDirectionY"  0.5 (linear 1.0  -0.5)))
					(effect "Light" (A)
						(param "LightNumber" 2)
						(param "LightAmbientB" 0.0)
						(param "LightAmbientG" 0.5)
						(param "SpotDirectionX"  0.5 (linear 0.5  0.5)
									     (linear 1.0 -0.5))
						(param "SpotDirectionY"  0.5 (linear 0.5  0.5)
									     (linear 1.0 -0.5)))
					(effect "Light" (A)
						(param "LightNumber" 1)
						(param "LightAmbientR" 0.0)
						(param "LightAmbientG" 0.5)
						(param "SpotDirectionY" -0.5 (linear 0.5  0.5)
									     (linear 1.0 -0.5)))
					(effect "Light" (A)
						(param "LightAmbientR" 0.0)
						(param "LightAmbientG" 0.0)
						(param "SpotDirectionX" -0.5 (linear 0.5  0.5)
									     (linear 1.0 -0.5)))
					(effect "Material" (A))))
]

The above style creates multiple instances of the Light effect with different colors and moves them across the screen.

@image["image/light_multiple.jpg"]
