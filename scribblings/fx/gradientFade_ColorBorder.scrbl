#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{GradientFade_ColorBorder}

This transition is the same thing as @secref["GradientFade"]. The only addition is that the style author can add color borders along the gradient between input A and input B. 

@bold{Important Note:} Ok here's the deal.. There are no parameters called @scheme[Feather], @scheme[Progress] or @scheme[BorderColor], per se. We are using generic parameters from the @secref["Mask"] effect internally to create a Colored Gradient fade. See the sample usage. 

@scheme[a0,r0,g0,b0] is used to represent the @scheme[Progress].

@scheme[a1,r1,g1,b1] is used to represent the @scheme[Feather].

@scheme[a2,r2,g2,b2] is used to represent the @scheme[BorderColor].


@effect-parameter-table[
                        [Path n/a @list{n/a} @list{The full path of the gradient map}]
                        
                        [Feather  10 @math{>0} @list{Creates an alpha gradient at the edges of the gradient. A low value means we have a huge gradient and vice versa}]
                        
                        [Progress n/a @scheme[n/a] @list{The Progress parameter dictates the gradient fade speed with respect to the transition time. Read important note in feather description}]
                        
                        [BorderColor {1.0, 1.0, 1.0, 1.0} @math{(0.0 - 1.0)} @list{The border color between input 0 and input 1.  Read important note in feather description}]
                        
                        [NumParams 0.0 @math{3.0} @list{This value MUST be set to 3}]
                        
                        [ProgramString n/a @list{n/a}  @list{@itemize{
                                                                   @item{@scheme[GradientFade_Reverse_Sepia_ColorBorder] Sepia tone the input and then do reverse GF}
                                                                   @item{@scheme[GradientFade_Reverse_Desaturated_ColorBorder] Desaturate the input and then do reverse GF}
                                                                   @item{@scheme[GradientFade_Reverse_Saturated_ColorBorder] Saturate the input and then do reverse GF}
                                                                   @item{@scheme[GradientFade_Reverse_Normal_ColorBorder] Show the normal unmodified input and then do reverse GF}
                                                                   @item{@scheme[GradientFade_Forward_Greyscale_ColorBorder] Greyscale the input and then do forward GF}
                                                                   @item{@scheme[GradientFade_Forward_Sepia_ColorBorder] Sepia tone the input and then do forward GF}
                                                                   @item{@scheme[GradientFade_Forward_Desaturated_ColorBorder] Desaturate the input and then do forward GF}
                                                                   @item{@scheme[GradientFade_Forward_Saturated_ColorBorder] Saturate the input and then do forward GF}
                                                                   @item{@scheme[GradientFade_Forward_Normal_ColorBorder] Show the normal unmodified input and then do reverse GF}}}]
                        ]

@input-and-imageop[(A) "Yes."]


@section{A gradient fade between two pictures}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   A color border gradient fade example.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-transition
  (layers (A B)

          (code:comment "Input B is drawn first")
          B
          
          (effect "Mask" () 
                  (input 0 A)
                  (param "ProgramString"  GradientFade_Forward_Normal_ColorBorder)
                  
                  (param "a0" 0.0 (linear 1.0 1.2))	(code:comment "progress")
                  (param "r0" 0.0 (linear 1.0 1.2))	(code:comment "progress")
                  (param "g0" 0.0 (linear 1.0 1.2))	(code:comment "progress")
                  (param "b0" 0.0 (linear 1.0 1.2))	(code:comment "progress")
                  
                  (param "a1" 0.1)	(code:comment "feather a")
                  (param "r1" 0.1)	(code:comment "feather r")
                  (param "g1" 0.1)	(code:comment "feather g")
                  (param "b1" 0.1)	(code:comment "feather b")
                  
                  (param "a2" 1.0)		(code:comment "border color a")
                  (param "r2" 0.22)		(code:comment "border color r")
                  (param "g2" 0.74)		(code:comment "border color g")
                  (param "b2" 0.93)		(code:comment "border color b")
                  
                  (param "NumParams" 3)
                  (param "Path" (resource "gradientmap.png"))
                  (param "Quality" 3))))

]

@image["image/GradientFade_ColorBorder.jpg"]

The gradient map that was used is shown below.

@image["image/GradientMap.png"]




