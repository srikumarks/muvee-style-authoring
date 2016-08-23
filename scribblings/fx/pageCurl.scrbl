#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{PageCurl}

Treats its input textures as components of a page and ``turns'' them by curling their geometry. You can also cause the pages to roll instead, simulating a scroll.

@effect-parameter-table[
[Angle 135.0 @math{[0.0,360.0]}
       @list{The angle at which we start the curl. Below are four examples:
                 @itemize{
                          @item{@scheme[45]: Curl Top Right}
                          @item{@scheme[135]: Curl Bottom Right}
                          @item{@scheme[225]: Curl Bottom Left}
                          @item{@scheme[315]: Curl Top Left}
                          }}]
[Mode  0 @math{{0,1}}
       @list{PageCurl can operate in two distinct modes
                      @itemize{
                               @item{@scheme[0]: PageCurl mode}
                               @item{@scheme[1]: Roll mode}}}]
[Curl  1.5 @math{> 1.0}
       @list{The degree of the curl. High values will cause the curl to be smaller and vice versa. You can think of it as the radius of the curl, expressed in the units of the scene's geometry.}]
]

@input-and-imageop[(A) #t]

@section{Examples}

@subsection{The PageCurl transition}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My head-banging earth-shaking style")
(code:comment "This style has a PageCurl transition.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "CropMedia" (A))
				(effect "Perspective" (A))))


(define muvee-transition 
  (layers ( A B )
          B	
          (effect "PageCurl" ()
                  (input 0 A))))

]

This style creates a PageCurl effect. In the @seclink["Transitions"]{muvee-transition}, we create a @secref["layers"] with inputs @scheme[A] and @scheme[B]. We display @scheme[B] as it is because no effects are applied to it. For @scheme[A], we display it in front of @scheme[B] and apply the @scheme["PageCurl"] effect to it. We have not modified any parameter but you are free to do so if the need arises.

@image["image/pageCurl.jpg"]



@subsection{The Roll transition}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My head-banging earth-shaking style")
(code:comment "This style has a Roll transition.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				(effect "CropMedia" (A))
				(effect "Perspective" (A))))


(define muvee-transition 
  (layers ( A B )
          B	
          (effect "PageCurl" ()
                  (input 0 A)
                  (param "Mode" 1)
                  (param "Curl" 1.0))))

]

This style creates a roll effect. The code layout is rather similar to the first example. The only difference is that we have set the @scheme[Mode] parameter to @scheme[1] and decreased the @scheme[Curl] parameter to @scheme[1.0]. 

@image["image/roll.jpg"]
