#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{FragmentProgram}

Alright folks, we're getting into some hard-core stuff here. If you do not possess a programming background, may I suggest you skip this page. Failure to do so will only result in pain and suffering. :D


OpenGL allows you to code up fragment Programs which are basically pieces of assembly code. Fragment programs are good in cases when you want to add custom color effects to your muvee. An example of a fragment programs (amongst many others) that has been written for you is the @secref["Greyscale"] effect. For a brief introduction of what a fragment program is, check out the @link["http://en.wikipedia.org/wiki/ARB_(GPU_assembly_language)"]{wikipedia entry}. If you wish to read the proper technical page for fragment programs, please read @link["http://oss.sgi.com/projects/ogl-sample/registry/ARB/fragment_program.txt"]{this}.




@section{Parameters}
 
@effect-parameter-table[
                        [ProgramString "" @list{n/a} @list{The fragment program string }]
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
                        
                        [GlobalMode  0 @math{[0,1]}  @list{See @tech{GlobalMode}}]
    
                        ]


@input-and-imageop[(A) "Depends on the GlobalMode parameter."]


@section{Examples}

@subsection{The most basic fragment program}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My not-so-awesome style.")
(code:comment "   This style does absolutely nothing..")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))
]

@tt{@"  ("}@scheme[define] @scheme[shader-program]
@verbatim{"!!ARBfp1.0
TEMP texfrag; 
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MOV result.color, texfrag;                                            
END"}@tt{@"  )"}
  
@schemeblock[
(define muvee-segment-effect 
  (effect "FragmentProgram" (A)
          (param "ProgramString" shader-program)))
]

The above style instantiates a @scheme[FragmentProgram] with a very simple assembly program. Every fragment program must start with @scheme[!!ARBfp1.0] and end with @scheme[END].This is by design and you are expected to follow that rule. The @scheme[texfrag] variable is initialized to contain the user image pixels. And all we do with it is copy it to the output buffer. Essentially the fragment program does nothing interesting. Do note that this program is executed for every pixel (referred to as a fragment in OpenGL). So at any given time, texfrag contains the RGBA values of a single pixel. 


@image["image/original.jpg"]


@subsection{A fragment program that greyscales the user image}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My  kinda awesome style.")
(code:comment "   This style greyscales the user image")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))
]

@tt{@"  ("}@scheme[define] @scheme[shader-program]
@verbatim{"!!ARBfp1.0
TEMP texfrag; 
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
TEMP gray;
ADD  gray, texfrag.r, texfrag.g;
ADD  gray, gray, texfrag.b;
MUL  gray, gray, 0.33;
MOV result.color, gray;                                            
END"}@tt{@"  )"}
  
@schemeblock[
(define muvee-segment-effect 
  (effect "FragmentProgram" (A)
          (param "ProgramString" shader-program)))
]

The above style converts the user image to greyscale. That's not exactly how we would usually do a greyscale but it's the simplest version to explain. Essentially we create a @scheme[gray] variable, add up the @scheme[r], @scheme[g], @scheme[b] values of our user image and divide the sum by @scheme[3.0] Finally we move the result stored in @scheme[gray] to @scheme[result.color]. Et voila!

@image["image/greyscale.jpg"]




@subsection{A fragment program that extracts a particular color}

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
]

@tt{@"  ("}@scheme[define] @scheme[shader-program]
@verbatim{"!!ARBfp1.0
TEMP texfrag;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
}
@verbatim{
#ColorInterest is linked to (a0,r0,g0,b0)
PARAM ColorInterest  = program.local[0];
}
@verbatim{
#ColorTolerance is linked to (a1,r1,g1,b1)
PARAM ColorTolerance = program.local[1];
}
@verbatim{
#LRPTolerance is linked to (a2,r2,g2,b2)
PARAM LRPTolerance = program.local[2];
}
@verbatim{
#Let's find the distance of the current pixel
#to the ColorInterest value
TEMP distance;
SUB distance, ColorInterest, texfrag;
DP3 distance, distance, distance;
}
@verbatim{
#Is the distance above or below the tolerance level.
TEMP distanceCMP;
SLT distanceCMP, distance, ColorTolerance;
SUB distanceCMP, distanceCMP, 0.5;
}
@verbatim{
#The initial set of pixel that passed. ie distance < tolerance
TEMP texfragA;
MOV  texfragA, texfrag;
MOV  texfragA.a, 1.0;
}
@verbatim{
#This section tries to do a linear interpolation just after tolerance
#else well get a sudden stop when our threshold is exceeded.
TEMP gradient;
TEMP scrap;
SUB gradient, distance, ColorTolerance;
RCP scrap.r, LRPTolerance.r;
MUL_SAT gradient, gradient, scrap.r;
}
@verbatim{
LRP gradient, gradient, 0.0, texfragA; 
}
@verbatim{
TEMP finalColor;
CMP  finalColor, distanceCMP, gradient, texfragA;
MUL  finalColor, finalColor, fragment.color.a;
}
@verbatim{
MOV result.color, finalColor;
}
@verbatim{
END"}@tt{@"  )"}
  
@schemeblock[
(define muvee-segment-effect 	
  (layers (A)
          (effect "Greyscale" ()
                  (input 0 A))
          
          (effect "FragmentProgram" ()
                  (input 0 A)
                  (param "ProgramString" shader_program)
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

The above style is slightly more complicated than the first two examples. Ok ok it's a lot more complicated that the first two examples. The @scheme[FragmentProgram] is a color selector. From muse, we send in the color we want to retain (referred to as our @scheme[colorInterest]) and the @scheme[fragmentProgram] returns sections of the picture with that color. Refer to the screenshot below for a visual reference. As you can see, only things that are colored blue are displayed as is. The rest are greyscaled.

If you look at the @seclink["The_segment_effect"]{segment-level-effect}, our @seclink["layers"]{layers} has two effect. The first one is a  @secref["Greyscale"] effect and the next one is our @bold{FragmentProgram} that will only return stuff that are colored blue. The @scheme[{a0,r0,g0,b0}] set of paramters initialize the color we want to retain. As you can see, it's set to blue. The @scheme[{a1,r1,g1,b1}] sets the threshold at which we'll accept colors. Finally @scheme[{a2,r2,g2,b2}] sets the amount of interpolation we want *after* the threshold. The best way to understand what I mean is to set it to zero, you'll then appreaciate its function. 


@image["image/fragmentProgram.jpg"]