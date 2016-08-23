#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{TextureSubset}

Selects a portion of its input image.

If you want to break up your picture (or video) into @scheme[4] smaller rectangles that move in different directions, @scheme["TextureSubset"] is the effect for you. Three shapes are supported. You have have a rectangular subset of your original image. You can also have circular subset of your picture (or video) and finally you can have a triangular subset of your picture (or video).

@effect-parameter-table[
[mode 0 @scheme[{0,1,2}]
      @list{Three distinct shapes can be drawn.
                  @itemize{
                           @item{@scheme[0] : rectangle shape}
                           @item{@scheme[1] : circle shape}
                           @item{@scheme[2] : triangle shape}}}]
[centered 0.0 @scheme[{0,1}]
          @list{Centers the texture subset on the screen.}]
]

The interpretation of other parameters depends on @scheme[mode].

@subsubsub*section{For @bold{Rectangle} shape:}

Only parameters @scheme[x0], @scheme[y0], @scheme[x1] and @scheme[y1] are used.
They extract a region bounded by coordinates @math{(x0, y0)} and @math{(x1, y1)}. The coordinates @math{(0, 0)} refer to the bottom-left corner of the texture image, while @math{(1, 1)} refer to the top-right corner.

@effect-parameter-table[
[x0 0.0 @scheme[(0.0 - 1.0)] 
    @list{Left boundary of the texture image.}]
[y0 0.0 @scheme[(0.0 - 1.0)] 
    @list{Bottom boundary of the texture image.}]
[x1 1.0 @scheme[(0.0 - 1.0)]
    @list{Right boundary of the texture image.}] 
[y1 1.0 @scheme[(0.0 - 1.0)]
    @list{Top boundary of the texture image.}] 
]

@subsubsub*section{For @bold{Circle} shape:}
       
Only parameters @scheme[x0] and @scheme[y0] and @scheme[radius] are used.
@math{(x0,y0)} refers to the center of the circle. @scheme[radius] is the radius of the circle. (really?)

@effect-parameter-table[ 
[x0 0.0 @scheme[(0.0 - 1.0)] 
    @list{x coordinate of center point of circle.}]
[y0 0.0 @scheme[(0.0 - 1.0)] 
    @list{y coordinate of center point of circle.}]
[radius 1.0 @scheme[(0.0 - 1.0)] 
        @list{The radius of the circle.}]
]

@subsubsub*section{For @bold{Triangle} shape:}
          
Only parameters @scheme[x0], @scheme[y0], @scheme[x1], @scheme[y1], @scheme[x2] and @scheme[y2] are used.
The three @math{(x@subscript{n},y@subscript{n})} coordinates refer to the three points of the triangle.

@effect-parameter-table[ 
[x0 0.0 @scheme[(0.0 - 1.0)] 
    @list{x coordinate of first point of triangle.}]
[y0 0.0 @scheme[(0.0 - 1.0)]
    @list{y coordinate of first point of triangle.}]
[x1 1.0 @scheme[(0.0 - 1.0)]
    @list{x coordinate of second point of triangle.}]
[y1 1.0 @scheme[(0.0 - 1.0)]
    @list{y coordinate of second point of triangle.}]
[x2 1.0 @scheme[(0.0 - 1.0)]
    @list{x coordinate of third point of triangle.}]
[y2 1.0 @scheme[(0.0 - 1.0)]
    @list{y coordinate of third point of triangle.}]
]

@input-and-imageop[(A) #t]

@section{Examples}

@subsection{Creating a triangular subset}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My kick-butt style")
(code:comment "   This style creates a triangular subset of the original image")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "CropMedia" (A))
				(effect "Perspective" (A))))

(define muvee-segment-effect (effect "TextureSubset" (A) 
                                     (param "mode" 2)
                                     (param "x0" 0.25)
                                     (param "y0" 0.25)
                                     (param "x1" 0.75)
                                     (param "y1" 0.25)
                                     (param "x2" 0.50)
                                     (param "y2" 1.00)))
]

@image["image/textureSubset_Triangle.jpg"]

@subsection{Creating an animated circular subset}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My kick-butt style")
(code:comment "   This style creates an animated circular subset of the original image")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "CropMedia" (A))
				(effect "Perspective" (A))))

(define muvee-segment-effect (effect "TextureSubset" (A) 
					  (param "mode" 1)
					  (param "x0" 0.5)
					  (param "y0" 0.5)
					  (param "radius" 1.0 (linear 1.0 0.0))))
]

@image["image/textureSubset_Circle.jpg"]


@subsection{Creating a rectangular subset of the original image.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My head-banging earth-shaking style")
(code:comment "This style creates a small rectangular subset of the original image.")
(code:comment "")
(code:comment "Copyright (c) 2008 muvee Technologies Pte Ltd.")
(code:comment "All rights reserved.")
             
(style-parameters)
             
(segment-durations 8.0)
             
(define muvee-global-effect (effect-stack
                             (effect "CropMedia" (A))
                             (effect "Perspective" (A))))


(define muvee-segment-effect (effect "TextureSubset" (A) 
                                     (param "mode" 0)
                                     (param "x0" 0.25)
                                     (param "y0" 0.25)
                                     (param "x1" 0.75)
                                     (param "y1" 0.75)))
]

@image["image/textureSubset_Quad.jpg"]

The above example breaks up our picture into @scheme[1] rectangle. I have chosen coordinate @math{(0.25, 0.25)} as the bottom left corner of my rectangle and @math{(0.75, 0.75)} as the top right coordinate.




@subsection{Breaking a picture into 4 individual rectangles}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My head-banging earth-shaking style")
(code:comment "This style breaks up the input into 4 rectangles")
(code:comment "")
(code:comment "Copyright (c) 2008 muvee Technologies Pte Ltd.")
(code:comment "All rights reserved.")
             
(style-parameters)
             
(segment-durations 8.0)
             
(define muvee-global-effect (effect-stack
                             (effect "CropMedia" (A))
                             (effect "Perspective" (A))))

(define (texture-subset A (x0 y0) (x1 y1))
  (effect "TextureSubset" () 
          (input 0 A)
          (param "mode" 0)
          (param "x0" x0)
          (param "y0" y0)
          (param "x1" x1)
          (param "y1" y1)))

(define muvee-segment-effect (layers (A)
        (code:comment "Bottom Left")
        (texture-subset A (0.0 0.0) (0.499 0.499))
                                     
        (code:comment "Bottom Right")
        (texture-subset A (0.501 0.0) (1.0 0.499))
                                     
        (code:comment "Top Left")
        (texture-subset A (0.0 0.501) (0.499 1.0))
                                     
        (code:comment "Top Right")
        (texture-subset A (0.501 0.501) (1.0 1.0))))
]

@image["image/textureSubset_4Quads.jpg"]

The above example breaks up our picture into four rectangles. We are now introducing the concept of functions in this example. We have defined a function called @scheme[texture-subset] which takes five arguments, input @scheme[A] and four coordinates @scheme[(x0 y0)] and @scheme[(x1 y1)]. Inside the @seclink["The_segment_effect"]{muvee-segment-effect}, our function is called four times with different coordinates. Do note that we can move each rectangle independently by adding an @secref["effect-stack"] on top of each @scheme["TextureSubset"] followed by a @secref["Translate"] effect. Each rectangle has a width and height of 0.499. This creates a small black boundary between them. If the width and height is set to 0.5 we will end up with four rectangles that are perfectly aligned with one another. You are also free to use combinations of different @scheme["TextureSubset"] modes or different numbers of @scheme["TextureSubset"] instances at arbitrary coordinates. It's all up to you. 
