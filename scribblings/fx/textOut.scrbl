#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{TextOut}

Renders the given text onto a texture and inserts it into the scene as a layer. The non-text area is transparent.

@section{Parameters}
 
@effect-parameter-table[
[Text n/a "n/a" @scheme[The text we wish to print]]

[ShadowType 2 @scheme[{0,1,2,3}]  @list{ @itemize{   @item{@scheme[0: N0_SHADOW]}
                                                     @item{@scheme[1: HARD_SHADOW]}
                                                     @item{@scheme[2: SOFT_SHADOW]}
                                                     @item{@scheme[3: INNER_SHADOW]}}}]

[ShadowSize 0.0156 @scheme[(0.0 - 1.0)] @list{The normalized size of the shadow with respect to the frame width}]

[HorizShadow 0.00625 @scheme[(0.0 - 1.0)] @list{The normalized size of the horizontal shadow with respect to the frame width}]
[VertShadow 0.00833 @scheme[(0.0 - 1.0)] @list{The normalized size of the vertical shadow with respect to the frame height}]

[ShadowColor 0xFFFFFF @scheme[0x0 - 0xFFFFFF] @list{The shadow color in HEX format}]
[TextColor 0xFFFFFF @scheme[0x0 - 0xFFFFFF] @list{The color of the displayed text in HEX format}]

[HorizAlign 1 @scheme[{0,1,2}] @list{ @itemize{   @item{@scheme[0]: Left}
                                                  @item{@scheme[1]: Center}
                                                  @item{@scheme[2]: Right}}}]
[VertAlign 1 @scheme[{0,1,2}] @list{ @itemize{    @item{@scheme[0]: Top}
                                                  @item{@scheme[1]: Center}
                                                  @item{@scheme[2]: Bottom}}}]

[FadeText 1.0 @scheme[(0.0 - 1.0)] @list{The opacity of the text. This parameter can be animated}]

[LayoutX0 0.1 @scheme[(0.0 - 1.0)] @list{The left border of our printing area}]
[LayoutX1 0.9 @scheme[(0.0 - 1.0)] @list{The right border of our printing area}]
[LayoutY0 0.1 @scheme[(0.0 - 1.0)] @list{The top border of our printing area}]
[LayoutY1 0.9 @scheme[(0.0 - 1.0)] @list{The bottom border of our printing area}]

[FontType "-27,0,0,0,400,0,0,0,0,3,2,1,49, Default" "n/a" @list{Sets the font of the text. The different values follow the @link["http://msdn.microsoft.com/en-us/library/aa741230(VS.85).aspx"]{LOGFONTA} structure. The default font names available in windows can be found @link["http://blogs.msdn.com/michkap/archive/2006/04/04/567881.aspx"]{here}}]]

@input-and-imageop[(A) #f]

@section{Examples}

@subsection{Text printing on user media}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   It prints some style-defined text on the user media.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect (effect "TextOut" (A)
                                     (param "Text" "Hello World!")))

]

This is a very simple usage of the @scheme["TextOut"] effect. We only supplied the text we wanted to print. 
We have used the dafault font, color and position.

@image["image/textout.jpg"]



@subsection{Text printing on user media}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   This examples modifies the default parameters of the TextOut effect.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect 
  (effect-stack (effect "Perspective" (A))
                (effect "CropMedia" (A))))

(define muvee-segment-effect (effect "TextOut" (A)
                                     (param "Text" "I got a cookie!")                                     
                                     (param "FontType" "-27,0,0,0,400,0,0,0,0,3,2,1,49,Arial")
                                     (param "TextColor" 0x00FF00)
                                     (param "VertAlign" 2)))

]

In this examples, we set the color of the text to green (@scheme[0x00FF00] in Hex color) and change the font to Arial instead of the default font. Finally we set the vertical alignment to bottom. The result is the image shown below. 

@image["image/textout2.jpg"]
