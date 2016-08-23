#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{PictureQuad}

Use this to bring an image file as a layer into your scene. You can use it for background images, frames, ornaments, etc. Supported image formats are png (supports transparency), jpeg and bmp. 
 
@effect-parameter-table[
[Path " " "n/a"
      @list{The path of the image file}]
[Quality 2 @math{{0, 1, 2, 3}}
         @list{@itemize{
                     @item{@scheme[0]: @scheme[Quality_Lowest]}
                     @item{@scheme[1]: @scheme[Quality_Lower]}
                     @item{@scheme[2]: @scheme[Quality_Normal]}
                     @item{@scheme[3]: @scheme[Quality_Higher]}}}]
[OnDemand 0 @math{{0,1}}
          @list{When 0, the image is loaded and kept alive for the life of the muvee. When 1, it is loaded only on demand to minimize texture memory consumption. Use 1 for large backgrounds that are not used in every segment. That way, you can have as many backgrounds as you want without incurring any additional texture memory overhead.}]
]

@input-and-imageop[() #f]

@section{Examples}

@subsection{Simple PictureQuad usage as a background}

The simple muvee style below loads an picture background and displays the user media on top of it.


@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect	(layers (A) 
				   (effect "PictureQuad" ()	
				        (param "Path" (resource "background.jpg")))
									
				   (effect "Scale" ()
					(input 0 A )
					(param "x" 0.8)
					(param "y" 0.8))))


]

This style does 2 main things. They are:
@itemize{ 
 @item{Creates a Picture using the @scheme[PictureQuad] effect.}
 @item{Scales that input media to 80% of its original length. This is done so that the @scheme[PictureQuad] will be bigger than the user media, thus making it visible.}
 }

We have introduced the concept of @secref["layers"] in the example. Here's what happens: The @scheme["PictureQuad"] effect does not take any input, but we want to display the user media in front of the @scheme["PictureQuad"]. So we create a Layer in which we have both input A ( which is the user picture ) and the @scheme["PictureQuad"] effect. That results in the nice screen shot you see below.

Do also note that the @secref["Scale"] effect is not written as 

@schemeblock[(effect "Scale" (A) ....)]

but rather as

@schemeblock[
(effect "Scale" ()
`       (input 0 A) ....)
]


The reason we do that is because the input media is called slightly differently within a @seclink["layers"]{Layers}. Inside a @seclink["layers"]{Layers}, we can use the input media without any effect by writing the letter @scheme[A]. Or we can use @scheme[(input 0 A)] if we are calling the media within an effect.


@image["image/pictureQuad.jpg"]

@subsection{Simple PictureQuad usage as an overlay}

@schemeblock[
(code:comment "muSE v2")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define muvee-segment-effect (layers (A) 
                                     A								
                                     (effect "PictureQuad" ()	
                                             (param "Path" (resource "overlay.png")))))

]

In this example, we first draw the user media, denoted by the letter @scheme[A]. Then we draw the overlay file after it. Do note that the overlay file is a png file that has been created with a transparent region ( i.e. an alpha of 0.0 ) anywhere the overlay does not have any material of interest.

@image["image/pictureQuadOverlay.jpg"]