#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Mask}

The Mask effect is an extended version of  @link["http://muvee-style-authoring.googlecode.com/svn/doc/main/FragmentProgram.html"]{FragmentProgram} effect. Please make sure you've understood how the @scheme[FragmentProgram] effect works before reading about this effect.

The Mask effect allows you to load an image file and make it interact with your picture by using a fragment program. For example, you could use the Mask effect to make gradient fades or make some really nice bump mapping effect.


@section{Parameters}
 
@effect-parameter-table[
                        [Path "" @list{n/a} @list{The full path of the mask filename}]
                        [ProgramString "" @list{n/a} @list{The fragment program string}]
                        [NumParams 0 @math{(0 - 16)} @list{The number of parameters we are specifying. There is a mechanism where you can send data from the muse code to the fragment program}]
                                   
                        [r0 0.0 @list{n/a} @list{The value of parameter r0}]
                        [g0 0.0 @list{n/a} @list{The value of parameter g0}]
                        [b0 0.0 @list{n/a} @list{The value of parameter b0}]             
                        [a0 0.0 @list{n/a} @list{The value of parameter a0}]
                        [r1 0.0 @list{n/a} @list{The value of parameter r1}]
                        [g1 0.0 @list{n/a} @list{The value of parameter g1}]
                        [b1 0.0 @list{n/a} @list{The value of parameter b1}]
                        [a1 0.0 @list{n/a} @list{The value of parameter a1}]
                        [r2 0.0 @list{n/a} @list{The value of parameter r2}]
                        [g2 0.0 @list{n/a} @list{The value of parameter g2}]
                        [b2 0.0 @list{n/a} @list{The value of parameter b2}]
                        [a2 0.0 @list{n/a} @list{The value of parameter a2}]
                        [r3 0.0 @list{n/a} @list{The value of parameter r3}]
                        [g3 0.0 @list{n/a} @list{The value of parameter g3}]
                        [b3 0.0 @list{n/a} @list{The value of parameter b3}]
                        [a3 0.0 @list{n/a} @list{The value of parameter a3}]
                        
                        [TranslateX 0.0 @list{n/a} @list{ The amount the mask should be translated in the x-axis}]
                        [TranslateY 0.0 @list{n/a} @list{ The amount the mask should be translated in the y-axis}]
                        [TranslateZ 0.0 @list{n/a} @list{ The amount the mask should be translated in the z-axis}]
                        [ScaleX 0.0 @list{n/a} @list{ The amount the mask should be scaled in the x-axis}]
                        [ScaleY 0.0 @list{n/a} @list{ The amount the mask should be scaled in the y-axis}]
                        [ScaleZ 0.0 @list{n/a} @list{ The amount the mask should be scaled in the z-axis}]
                        
                        [RotateAxisX 0.0 @math{{0.0,1.0}}  @list{This flag set the rotation (if any) along the x-axis}]
                        [RotateAxisY 0.0 @math{{0.0,1.0}}  @list{This flag set the rotation (if any) along the y-axis}]
                        [RotateAxisZ 0.0 @math{{0.0,1.0}}  @list{This flag set the rotation (if any) along the z-axis}]
                        
                        [RotateAngle 0.0 @list{n/a} @list{The angle in degrees by which we want to rotate}]
                        
                        [CropMedia 1 @math{{0,1}} @list{
                                                      @itemize{
                                                               @item{@scheme[0] means we will stretch the image so that it fits the screen. It will slightly distort the image where picture aspect ratio and screen aspect ratio differ.}
                                                               @item{@scheme[1] means we crop the image to fit the screen. The image will not be distorted but the be appropriately cropped at the edges.}}}]
                        
                        [FlipMode 0 @math{{0,1,2,3,4}} @list{
                                                      @itemize{
                                                               @item{@scheme[0 FlipMode_None] - display the mask in its original orientation}
                                                               @item{@scheme[1 FlipMode_Horizontal] - Flip the mask  orientation horizontally}
                                                               @item{@scheme[2 FlipMode_Vertical] - Flip the mask orientation vertically}
                                                               @item{@scheme[3 FlipMode_HorizontalAndVertical] - Flip the mask both horizontally and vertically.}
                                                               @item{@scheme[4 FlipMode_Random] - Randomly flip the mask}}}]
                        
                                                                    
                        [Quality 2 @math{{0, 1, 2, 3}}
                                 @list{@itemize{
                                                @item{@scheme[0: Quality_Lowest]}
                                                @item{@scheme[1: Quality_Lower]}
                                                @item{@scheme[2: Quality_Normal]}
                                                @item{@scheme[3: Quality_Higher]}}}]   
                                                
                        [GlobalMode  0 @math{[0,1]}  @list{
                                                      @itemize{
                                                               @item{@scheme[0]: This means that the effect is a segment-level effect. What that implies is the effect is an @tech{Image-Op}. }
                                                               @item{@scheme[1]: This means that the greyscale effect is a global-level effect}}}]

                        ]


@input-and-imageop[(A) "Depends on parameter settings"]


@section{Examples}

@subsection{Mask example}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My awesome style.")
(code:comment "   This style demonstrates the mask effect.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))
]

@tt{@"  ("}@scheme[define] @scheme[shader-program]
@verbatim{"!!ARBfp1.0
TEMP texfrag, mask;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
TEX mask, fragment.texcoord[1], texture[1], 2D;
TEMP inter;
MUL inter, mask, texfrag;
MOV result.color, inter;
END"}@tt{@"  )"}
  
@schemeblock[
(define muvee-segment-effect 
  (effect "Mask" (A)
          (param "Path" (resource "Maskmuvee.jpg"))
          (param "ProgramString" shader-program)
	  (param "TranslateX" -0.35 (linear 1.0 0.35))
          ))
]

The Mask effect loads up and image, and the fragment program multiplies the two images together. Additionally the effect translates the mask along the x-axis from @scheme[-0.35] to @scheme[0.35]. The Mask effect is a rather powerful effect. Another effect that was written based on the Mask effect is the @secref["GradientFade_ColorBorder"] effect.


This is a screenshot of the output:

@image["image/mask.jpg"]


The image below is the mask that was used.

@image["image/Maskmuvee.jpg"]
