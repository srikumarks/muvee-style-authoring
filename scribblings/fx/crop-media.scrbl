#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{CropMedia}

User photos in muvee Reveal appear with a gentle pan/zoom effect - also known as "The Ken Burns effect" after the film make Ken Burns who popularized its narrative uses. There are two ways to achieve the pan/zoom on a photo -
@itemize{
         @item{A. By fixing the visible region of an image and scaling and translating it to show only the regions of interest, and}
         @item{B. By fixing the geometry, but animating the selected region of the image to mimic the pan/zoom.}}
Both techniques have their uses, but muvee Reveal defaults to using the scaling/translating approach. In some styles such as @emph{Scrap book}, the geometry of a photo is fixed and we need to perform the Ken Burns effect using approach (B).

The @scheme[CropMedia] effect switches the mode to approach (B) for all elements of the scene that it controls. In that sense, it is not really a visible effect, but a scene presentation setting masquerading as one. 

@effect-parameter-table[]

@input-and-imageop[() "No"]

@section{Behaviour of an image with @scheme[CropMedia] enabled}

@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "   My super awesome style.")
(code:comment "   This style desmonstrates the cropmedia effect.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
                                (effect "CropMedia" (A))
				(effect "Perspective" (A))))

(define muvee-segment-effect (effect "Translate" (A) 
				     (param "z" -1.0)))

]

Our main focus is the @seclink["The_global_effect"]{global effect}. That's where the @scheme[CropMedia] effect is usually declared. Now, what we're doing in the @seclink["The_segment_effect"]{segment effect} is simply move the user image further in the z-axis by @scheme[-1.0] units. To fully appreciate the use of @scheme[CropMedia], run the above style once; Then run it again after deleting the line @scheme[(effect "CropMedia" (A))]. You will then understand what is meant by @emph{region of interest}.

Do note that many styles declare @scheme[CropMedia] and @scheme[Perspective] as Global Effects. This is a rather standard use of @scheme[CropMedia] and you're encouraged to adopt it if you need the @scheme[CropMedia] approach.

@image["image/scale_anim_xy.jpg"]