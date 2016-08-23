#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{SeamlessBackground}

Same as @secref{PictureQuad} except that if you place two images next to each other, there will be no join seam visible. This is useful for tiling images.
 
@effect-parameter-table[
[Path " " "n/a"
      @list{The path of the image file}]
[Quality 2 @math{{0, 1, 2, 3}} 
         @list{@itemize{
                     @item{@scheme[0]: Quality_Lowest}
                     @item{@scheme[1]: Quality_Lower}
                     @item{@scheme[2]: Quality_Normal}
                     @item{@scheme[3]: Quality_Higher}}}]
[OnDemand 0 @math{{0,1}}
          @list{When 0, the image is loaded and kept alive for the life of the muvee. When 1, it is loaded only on demand to minimize texture memory consumption. Use 1 for large backgrounds that are not used in every segment. That way, you can have as many backgrounds as you want without incurring any additional texture memory overhead.}]
[ScaleX 1.0 @math{(0.0,1.0]} 
        @list{We can choose to scale the image before it is displayed. This parameter is the x-axis scale}]
[ScaleY 1.0 @math{(0.0,1.0]} 
        @list{We can choose to scale the image before it is displayed. This parameter is the y-axis scale}]
]

@input-and-imageop[() #f]

@section{Examples}

@subsection{Seamlessbackground example}


@schemeblock[
(code:comment "muSE v2")
(code:comment "My awefully nice style.")
(code:comment "This style creates a nice slide with a continuous background.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "Perspective" (A))
				(effect "CropMedia" (A))))
								
(define background (looping-sequence "01.jpg" "02.jpg"))

(define option1 
  (layers (A)
          (code:comment "display the background")
          (effect "PictureQuad" ()
                  (param "Path" (resource (background))))
          
          (code:comment "Translate the user image it by 0.01 in the z-axis.")
          (code:comment "We also scale it to 0.8 its original size.")
          (code:comment "Else it'll completely cover the background")
          (effect-stack
           (effect "Translate" (A)
                   (param "z" 0.01))
           (effect "Scale" ()
                   (input 0 A)
                   (param "x" 0.8)
                   (param "y" 0.8)))))

(define option2 
  (layers (A)
          (code:comment "display the background")
          (effect "SeamlessBackground" ()
                  (param "Path" (resource (background))))
          
          (code:comment "Translate the user image it by 0.01 in the z-axis.")
          (code:comment "we also scale it to 0.8 its original size.")
          (code:comment "Else it'll completely cover the background")
          (effect-stack
           (effect "Translate" (A)
                   (param "z" 0.01))
           (effect "Scale" ()
                   (input 0 A)
                   (param "x" 0.8)
                   (param "y" 0.8)))))


(code:comment "(define muvee-segment-effect option1)")
(define muvee-segment-effect option2)

(code:comment "This transition does the slide motion.")
(code:comment "Input A starts at rest and moves out of the screen")
(code:comment "Input B starts from outside and replaces inputA")
(define muvee-transition 
  (layers (A B)
          (code:comment "input A starts at x = 0 and ")
          (code:comment "end at x = -(1.999 * the screen aspect ratio)")
          (effect "Translate" ()
                  (input 0 A)
                  (param "x" 0.0 
                         (linear 1.0 (- 0.0 (* 1.999 render-aspect-ratio)))))

          (code:comment "input B starts at x = (1.999 * the screen aspect ratio)")
          (code:comment "and ends at x = 0.0")
          (effect "Translate" ()
                  (input 0 B)
                  (param "x" 
                         (* 1.997 render-aspect-ratio) (linear 1.0 0.0)))))


]

The style above displays the user image on top of some fancy background. The main feature of this style is that the background is continuous. Take a look at the two images below. The image on the left and the image on the right are continuous. If you were to join them together, it would feel as if you are looking at one really wide image.

@image["image/seamlessOrig01.jpg"]
@image["image/seamlessOrig02.jpg"]

Let's go back to the style code again. I have defined @scheme[option1] and @scheme[option2]. They are essentially the same code with the exception that the former uses @scheme[PictureQuad] and the latter uses @scheme["SeamlessBackground"]. The code above uses @scheme[option2]. You can try out @scheme[option1] by uncommenting it and commenting the line

@scheme[(define muvee-segment-effect option2)]

I have taken a screenshot of both options. They are displayed below:

Below is the seamlessBackground version.

@image["image/seamless1.jpg"]

Below is the pictureQuad version.

@image["image/seamless2.jpg"]


As you can see, @secref["PictureQuad"] is good in cases where you want to display one image. In cases where you want to align a bunch of pictures to make them look seamless, @scheme[SeamlessBackground] is the effect to use.

