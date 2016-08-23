#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{VertexProgram}

Alright folks, we're getting into some hard-core stuff here. If you do not possess a programming background, may I suggest you skip this page. Failure to do so will only result in pain and suffering. @scheme[:D]

A vertex program allows you to control the edges of your media. So you can distort you picture and make it do funky stuff.

OpenGL allows you to code up vertex Programs which are basically pieces of assembly code. The proper technical page for vertex program can be found @link["http://oss.sgi.com/projects/ogl-sample/registry/ARB/vertex_program.txt"]{here}.

@section{Parameters}
 
@effect-parameter-table[
                        [ProgramString "" "n/a" @list{The vertex program string}]
                        [NumParams 0 @scheme[(0 - 16)] @list{The number of parameters we are specifying. There is a mechanism where you can send data from the muse code to the vertex program}]
                        [UseGrid 1 @scheme[{0,1}] @list{Should we use a grid of 50x50 points to draw our image or just our regular 4 edges?}]
                                   
                        [r0 0.0 "n/a" @list{Red component of parameter 0.}]
                        [g0 0.0 "n/a" @list{Green component of parameter 0.}]
                        [b0 0.0 "n/a" @list{Blue component of parameter 0.}]             
                        [a0 0.0 "n/a" @list{Alpha component of parameter 0.}]
                        [r1 0.0 "n/a" @list{Red component of parameter 1.}]
                        [g1 0.0 "n/a" @list{Green component of parameter 1.}]
                        [b1 0.0 "n/a" @list{Blue component of parameter 1.}]
                        [a1 0.0 "n/a" @list{Alpha component of parameter 1.}]
                        [r2 0.0 "n/a" @list{Red component of parameter 2.}]
                        [g2 0.0 "n/a" @list{Green component of parameter 2.}]
                        [b2 0.0 "n/a" @list{Blue component of parameter 2.}]
                        [a2 0.0 "n/a" @list{Alpha component of parameter 2.}]
                        [r3 0.0 "n/a" @list{Red component of parameter 3.}]
                        [g3 0.0 "n/a" @list{Green component of parameter 3.}]
                        [b3 0.0 "n/a" @list{Blue component of parameter 3.}]
                        [a3 0.0 "n/a" @list{Alpha component of parameter 3.}]
                        
                        [GlobalMode  0 @scheme[{0,1}]  
                                     @list{
                                           @itemize{
                                                    @item{@scheme[0]: means that the effect is an @tech{Image-Op}. }
                                                         @item{@scheme[1]: means that the effect is a global-level composable effect.}}}]
                        ]

@input-and-imageop[(A) @list{If @scheme[GlobalMode] is set to @scheme[0].}]

@section{Examples}

@subsection{The most basic vertex program}

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
@verbatim{"!!ARBvp1.0

DP4 result.position.x, state.matrix.mvp.row[0], vertex.position;
DP4 result.position.y, state.matrix.mvp.row[1], vertex.position;
DP4 result.position.z, state.matrix.mvp.row[2], vertex.position;
DP4 result.position.w, state.matrix.mvp.row[3], vertex.position;

DP4 result.texcoord[0].x, state.matrix.texture.row[0], vertex.texcoord;
DP4 result.texcoord[0].y, state.matrix.texture.row[1], vertex.texcoord;
DP4 result.texcoord[0].z, state.matrix.texture.row[2], vertex.texcoord;
DP4 result.texcoord[0].w, state.matrix.texture.row[3], vertex.texcoord;

MOV result.color, vertex.color;

END"}@tt{@"  )"}
  
@schemeblock[
(define muvee-segment-effect
  (effect "VertexProgram" (A)
          (param "ProgramString" shader-program)))
]

The above code is the initializing code that every vertex program should have. After you're done multiplying the model-view matrix and the projection matrix to our coordinates, we multiply our coordinates with the texture matrix to ensure our pans and zooms show up in our production. From then on, you can start moving stuff around.


@image["image/original.jpg"]