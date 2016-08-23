#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Snow}
Superimposes a particle effect simulating falling snow on to the scene. The snow particle is given as a small image, typically a 50x50 png file (transparency supported).

@section{Parameters}
 
@effect-parameter-table[
                        [ParticleImage - "n/a" @list{The full path of the particle image. Specifying this parameter is mandatory.}]
                        [NumParticles 500 @math{> 0} @list{The number of particles present at any given time}]
                        [ParticleSize 0.04 @math{> 0} @list{The normalized size of the particle with respect to the screen}]
                        [ParticleAvgDurationSecs 5.0 @math{> 0} @list{The duration of each particle measured in seconds}]
                        [Alpha 0.7 @math{[0.0,1.0]} @list{The transparency of each particle. This parameter can be animated with a nice fade-in and fade-out effect}]
                        [Motion  2 @math{{0,1,2,3}}  @list{
                                                      @itemize{
                                                               @item{@scheme[0]: The particles fall straight down}
                                                               @item{@scheme[1]: The particles follow a sine curve while falling down}
                                                               @item{@scheme[2]: The particles follow a sine and cosine curve while falling down}
                                                               @item{@scheme[3]: The particles follows a parametric curve that causes the flakes to gall in bursts}}}]
                        [ParticleFlicker 1 @math{{0,1}} @list{If set to @scheme[1], the size of the particles will vary slightly as it falls down. Else the various particle size will remain static. Do note that the initial particle size is itself slightly randomized so that particle sizes are different at creation time}]                 

]

@input-and-imageop[() #f]

@section{Examples}

@subsection{Adding snow particles on top of the user image}

.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It adds snow on top of our user image.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))
				 (layers (A)
                                          A
					  (effect "Snow" ()
                                                  (param "ParticleImage" (resource "SnowParticle.png"))))))

]

@image["image/snow.jpg"]

The snow image @filepath{SnowParticle.png} that we provided to the effect is displayed below - 

@image["image/SnowParticle.png"]



@subsection{GreenPepper example}

The example is an abuse of the snow effect :) 
There is nothing that is preventing us from adding a completely different image of our own liking to the snow effect. In this example, I have added a small green pepper image to the snow effect.

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My somewhat funny style.")
(code:comment "   Adding falling green peppers on top of our user image.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))
				 (layers (A)
                                         A
                                         (effect "Snow" ()
                                                 (param "ParticleImage" (resource "GreenPepper.png"))
                                                 (param "Motion" 0)
                                                 (param "ParticleFlicker" 0)
                                                 (param "Alpha" 0.98)
                                                 (param "ParticleSize" 0.1)))))



]

@image["image/SnowPeppers.jpg"]

The snow image @filepath{GreenPepper.png} that we provided to the effect is displayed below - 

@image["image/GreenPepper.png"]

