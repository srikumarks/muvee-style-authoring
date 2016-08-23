#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{Shatter}

The Shatter transition breaks up input A into small hexagons and makes them fly off the screen to reveal input B.

@effect-parameter-table[
[Pattern 4 @math{{0,1,2,3,4,5,6}} 
         @list{@itemize{
                        @item{@scheme[0]: The order in which the hexagons start moving is completely random. The other patterns below create nice order whereby hexagons at the center move first and those at the edges move last amongst many others.}
                        @item{@scheme[1]: Hexagons on the left of the picture start moving out first and those on the right of the image move out last.}
                        @item{@scheme[2]: Hexagons on the right of the picture start moving out first and those on the left of the image move out last.}
                        @item{@scheme[3]: Hexagons start moving in a circle manner with those at the edges moving out first and those at the center moving out last.}
                        @item{@scheme[4]: Hexagons start moving in a circle manner with those at the edges moving out last and those at the center moving out first.}
                        @item{@scheme[5]: Hexagons start moving from top to bottom.} 
                        @item{@scheme[6]: Hexagons start moving from bottom to top.}}}]

[MoveX 0 @math{{-1,0,1}} 
       @list{@itemize{
                      @item{@scheme[-1]: Hexagons will move to the left}
                      @item{@scheme[ 0]: Hexagons will have no horizontal motion}
                      @item{@scheme[ 1]: Hexagons will move to the right}}}]
                                                                      
[MoveY 0 @math{{-1,0,1}}  
       @list{@itemize{
                      @item{@scheme[-1]: Hexagons will move to the bottom}
                      @item{@scheme[ 0]: Hexagons will have no vertical motion}
                      @item{@scheme[ 1]: Hexagons will move to the top}}}]
                        
[MoveZ 1 @math{{-1,0,1}}  
       @list{@itemize{
                      @item{@scheme[-1]: Hexagons will move away from screen}
                      @item{@scheme[ 0]: Hexagons will have no vertical motion}
                      @item{@scheme[ 1]: Hexagons will move towards the screen}}}]
                        
[PolygonLength 0.3 @math{> 0} 
               @list{The normalized length of the hexagon}]
                        
[RotateXaxis 1.0 @math{[0.0,1.0]} 
             @list{This represents normalized percentage of particles we want to rotate in the X-axis. 0.0 means we do not want any particle to rotate along the X axis. 1.0 means we want the maximum permissible number of particles to rotate along the X-axis.}]
                        
[RotateYaxis 1.0 @math{[0.0,1.0]}
             @list{This represents normalized percentage of particles we want to rotate in the X-axis. 0.0 means we do not want any particle to rotate along the Y axis. 1.0 means we want the maximum permissible number of particles to rotate along the Y-axis.}]
                                                
[RotateZaxis 1.0 @math{[0.0,1.0]} 
             @list{This represents normalized percentage of particles we want to rotate in the X-axis. 0.0 means we do not want any particle to rotate along the Z axis. 1.0 means we want the maximum permissible number of particles to rotate along the Z-axis.}]
                        
[RotateForceAxis -1 @math{{-1,0,1,2}}
                 @list{In case am individual hexagon has been randomly chosen to rotate in more than one dimension, we can force that particle to rotate in only one axis. -1 means we don't care around how many axes our particles rotate.}]
                        
[Reverse 0 @math{{0,1}}
         @list{If set to 1, the image will not break up into hexagons and fly out of the screen, but instead do the reverse, start as hexagons and reform the complete user picture.}]
                      
[RevPerProgress 1 @math{>= 0}
                @list{This parameter represents the number of revolutions each hexagon has to rotate around itself during the whole segment.}]
                        
[LastStartTime 0.1 @math{[0.0,1.0]} 
               @list{The normalized time at which the last particle starts moving. A value of 0.0 means all particles start moving together. A value of 1.0 means the first particle starts moving at progress of 0.0 and the last particle starts moving at a progress of 1.0f. }]
                        
[MoveOffset 1.0 @math{> 0} 
            @list{To create a semblance of randomness among the different particles, we add an offset to their motion.}]
                        
[z -1.0 "n/a" 
   @list{The total distance that the hexagons will travel at progress = 1.0. }]
]
                                 

@input-and-imageop[(A) #t]

@section{Examples}

@subsection{Video A shatters into small hexagons to reveal video B.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My good-looking style.")
(code:comment "A nice transition where our input breaks up into small hexagons and flies off the screen.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-transition (layers (A B)
                                  B
                                 (effect "Shatter" ()
                                         (input 0 A)
                                         (param "z" -2.0))))
]


@image["image/shatter.jpg"]





