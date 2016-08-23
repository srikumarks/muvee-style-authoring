#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{ColorSelect}

Filters out all colors except the color specified via the @scheme[r0], @scheme[g0] and @scheme[b0] parameters. The pixels filtered out are all mapped to transparent black.

@effect-parameter-table[

[ProgramString "" @list{n/a} @list{This must be set to @scheme[Color_Select].}]
[NumParams 0 @math{(0 - 4)} @list{This must be set to 3}]

[r0 0.0 @list{n/a} @list{The red component of the color to retain in the output.}]

[g0 0.0 @list{n/a}  @list{The green component of the color to retain in the output.}]

[b0 0.0 @list{n/a}  @list{The blue component of the color to retain in the output.}]             

[a0 0.0 @list{n/a}  @list{The alpha component of the color to retain in the output.}]

[r1 0.0 @list{n/a} @list{@scheme[r1], @scheme[g1], @scheme[b1] and @scheme[a1] give the tolerance range within a color is shown. For example, suppose the color component to be retained is 0.6 and the tolerance for that component is 0.1, then the colors whose component falls in the range @math{[0.5,0.7]} will show through.}]

[g1 0.0 @list{n/a} @list{The green component tolerance.}]

[b1 0.0 @list{n/a} @list{The blue component tolerance.}]

[a1 0.0 @list{n/a} @list{The alpha component tolerance.}]

[r2 0.0 @list{n/a} @list{@scheme[r2], @scheme[g2], @scheme[b2] and @scheme[a2] give the component-wise factors by which neighbouring pixels are blended together (anti-aliased) in order to smooth out jagged edges that occur in such selection operations.}]

[g2 0.0 @list{n/a} @list{The green anti-aliasing factor.}]

[b2 0.0 @list{n/a} @list{The blue anti-aliasing factor.}]

[a2 0.0 @list{n/a} @list{The alpha anti-aliasing factor.}]

[GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}.}]
]


@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]

@section{Extracting a color}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My  unbelievably awesome style.")
(code:comment "   This style greyscales the user image ")
(code:comment "   but maintains the stuff that are coloured blue. :)")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect 	
  (layers (A)
          (effect "Greyscale" ()
                  (input 0 A))
          
          (effect "FragmentProgram" ()
                  (input 0 A)
                  (param "ProgramString" Color_Select)
                  (param "a0"	1.0)	(code:comment "ColorInterest")
                  (param "r0"	0.0)	(code:comment "ColorInterest")
                  (param "g0"	0.0)	(code:comment "ColorInterest")
                  (param "b0"	1.0)	(code:comment "ColorInterest")
                  
                  (param "a1"	0.5)	(code:comment "ColorTolerance")
                  (param "r1"	0.5)	(code:comment "ColorTolerance")
                  (param "g1"	0.5)	(code:comment "ColorTolerance")
                  (param "b1"	0.5)	(code:comment "ColorTolerance")
                  
                  (param "a2"	0.6)	(code:comment "LRP Tolerance")
                  (param "r2"	0.6)	(code:comment "LRP Tolerance")
                  (param "g2"	0.6)	(code:comment "LRP Tolerance")
                  (param "b2"	0.6)	(code:comment "LRP Tolerance")
                  
                  (param "NumParams" 3))))
]

The @scheme[Color_Select] program string is a color selector shader. From muse, we send in the color we want to retain (referred to as our colorInterest) and the @scheme[Color_Select] returns sections of the picture with that color. Refer to the screenshot below. Only the blue colored pixels are retained and the rest are in grey.

If you look at the @seclink["The_segment_effect"]{segment-level-effect}, our @seclink["layers"]{layers} has two effect. The first one is a  @secref["Greyscale"] effect and the next one is our @bold{FragmentProgram} that will only return stuff that are colored blue. The @scheme[{a0,r0,g0,b0}] set of paramters initialize the color we want to retain. As you can see, it is set to blue. The @scheme[{a1,r1,g1,b1}] sets the threshold at which we'll accept colors. Finally @scheme[{a2,r2,g2,b2}] sets the amount of interpolation we want *after* the threshold. The best way to understand these parameters is to set them to zero, which effectively disables them, so you can compare the output with and the without the smoothing. 


@image["image/fragmentProgram.jpg"]