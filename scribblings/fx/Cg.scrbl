#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Cg}

@scheme[Cg] is a high-level programming language developped by Nvidia that allows developpers to move away from writing shader code in assembly language. If you have used the @secref["FragmentProgram"] effect, you will realize that making simple programs run on the GPU is no easy task. @scheme[Cg] allows you to write C-like code that is then converted to assembly code by the @scheme[Cg] compiler to be executed on your graphics card. Please be aware that you need to have a programming background to use this effect. More information on Cg can be found @link["http://http.developer.nvidia.com/CgTutorial/cg_tutorial_chapter01.html"]{here}. 

@section{Parameters}

The most important parameter of the @scheme[Cg] effect is @scheme[Program] using which you give the entire shader in string form to the effect, or pass a path to a file containing the shader program text. Obviously, you'll want to control some of the parameters of your shader. For that purpose, the @scheme[Cg] effect exposes all the parameters to your shader's @scheme[main] function as its own parameters automatically. See example below.

@effect-parameter-table[
[Program "" @list{n/a} @list{The Cg program string or the full path of the text file that contains the Cg program. You *must* set this parameter.}]
[GlobalMode  1 @math{[0,1]}  @list{See @tech{GlobalMode}}]
]


@input-and-imageop[(A) @list{Depends on the @scheme[GlobalMode] parameter.}]

@section{Simple usage}

The muvee style below gradually increases the saturation of the input picture.


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My unbelievably awesome style.")
(code:comment "   It manipulates the saturation of the user media.")

(style-parameters)

(segment-durations 8.0)
]
@tt{@"  ("}@scheme[define] @scheme[program-string] @tt{@"\""}
@verbatim{
struct fragment
{
	float4 position  : POSITION;
	float4 color0    : COLOR0;
	float2 texcoord0 : TEXCOORD0;
};
@" "
struct pixel
{
	float4 color : COLOR;
};
@" "
pixel main( fragment IN,
	    const uniform sampler2D inputTexture,
	    const uniform float1 	progress)
{
	pixel OUT;
@" "
   	float4 texelColor = tex2D( inputTexture, IN.texcoord0 );
@" "
	//Let us convert  RGB to YUV
	float4 weightY = {  0.29900,  0.58700,  0.11400, 1.0 };
	float4 weightU = { -0.14713, -0.28886,  0.43600, 1.0 };
	float4 weightV = {  0.61500, -0.51499, -0.10001, 1.0 };
@" "
	float4 Y = weightY * texelColor;
	float4 U = weightU * texelColor;
	float4 V = weightV * texelColor;
@" "
	float4 YUV;
	YUV.r = Y.r + Y.g + Y.b;
	YUV.g = U.r + U.g + U.b;
	YUV.b = V.r + V.g + V.b;
@" "
	//
	//Here we manipulate the YUV values
	//
	//YUV.r *= progress;
	YUV.g *= progress * 2.0;
	YUV.b *= progress * 2.0;
@" "
        //Let's convert YUV back to RGB
	float4 weightR = {1.0,  0.00000,  1.13983, 1.0};
	float4 weightG = {1.0, -0.39465, -0.58060, 1.0};
	float4 weightB = {1.0,  2.03211,  0.00000, 1.0};
@" "
	float4 R = weightR * YUV;
	float4 G = weightG * YUV;
	float4 B = weightB * YUV;
@" "
	OUT.color.a = texelColor.a * IN.color0.a;
	OUT.color.r = R.r + R.g + R.b;
	OUT.color.g = G.r + G.g + G.b;
	OUT.color.b = B.r + B.g + B.b;
@" "
	return OUT;	
}}@tt{@"\"  )"}

@schemeblock[
(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect  
  (effect "Cg" (A)	
          (param "Program"  program-string)
          (param "progress" 0.0 (linear 1.0 1.0))))

]


There is one important thing to note about the above Cg program - the @scheme["progress"] parameter's name is the name of the third parameter to the @scheme[main] function of the shader. If you change the name @scheme[progress] to, say, @scheme[saturation], then you'll have to write @scheme[(param "saturation" ...)] instead.

@verbatim{
pixel main( fragment IN, 
            const uniform sampler2D inputTexture, 
            const uniform float1 progress)
}

We recommend that you use @scheme[Cg] instead of the @secref["FragmentProgram"] effect because it is much easier to learn, write and debug, you make fewer errors and it lets you use advanced features of newer graphics cards when available. Do read @link["http://http.developer.nvidia.com/CgTutorial/cg_tutorial_chapter01.html"]{NVidia's CG documentation}. Have fun!

