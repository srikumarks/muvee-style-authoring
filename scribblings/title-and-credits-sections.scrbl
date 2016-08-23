#lang scribble/doc
@(require scribble/manual scribble/struct)

@title{Title and Credits}

@defproc*[[[(title-section ...) void] [(credits-section ...) void]]]{
These sections specify the default settings for the title and credits 
configurable settings and decide the particular look that the style
author wants to use for them that aligns with the style.

Below is a template @scheme[title-section] which illustrates all the
possible settings that can be specified. The same structure goes
for @scheme[credits-section] as well.

@schemeblock[
(title-section
    (code:comment "Background description, 4 possible types shown below,")
    (code:comment "but use only one!")
    (code:comment "1. a picture, typically jpg")
    (background (image "personal1.jpg"))
 
    (code:comment "2. solid background color, in RGB format, [default]")
    (background (color 0 0 0))
	
    (code:comment "3. video clip:See note below on usage of video files")
    (background (video "intro_30.avi"))

    (code:comment "4. arbitrary effect.")
    (background (color 0xFFFFFF)
                (fx ...arbitrary effect to use as background ...))

    (code:comment "Foreground object.")
    (foreground (fx ...global effect...))

    (code:comment "Optional background audio file.")
    (code:comment "The keyword arguments are optional.")
    (audio-clip "personal.mp3" gaindb: 0.0 fadein: 0.0 fadeout: 0.0)

    (code:comment "Text description")
    (text
        (code:comment "Text's color, in RGB format [default]")
        (color 255 255 255)

        (code:comment "Font - using Win32's LOGFONT structure")
        (font "-32,0,0,0,500,0,0,0,0,3,2,1,2,Batik Regular")

        (code:comment "Layout rectangle, in normalised coords")
        (code:comment "[default is TV-safe region]")
        (layout (0.1 0.1) (0.9 0.9))

        (code:comment "Text animation, You can use zero or more of these.")
        (fade-in duration: d 
                 initial: 0.0 
                 final: 1.0)
        (fade-out duration: d
                  initial: 1.0
                  final: 0.0)
        (zoom-in)
        (zoom-out)
        (typewriter)
        (color-reverse)

        (code:comment "Basic shadow effects, choose one [default is no shadow]")
        (soft-shadow dx: 1.0 dy: 1.0 size: 3.0)
        (hard-shadow dx: 1.0 dy: 1.0 size: 3.0)
        (inner-shadow dx: 1.0 dy: 1.0 size: 3.0)

        (code:comment "Text alignment - horizontal=left|center|right")
        (code:comment "and vertical=top|center|bottom")
        (align 'center 'center)

        (code:comment "Besides the above, you can explicitly specify any parameter ")
        (code:comment "exposed by [[TextOut]] using <param> tags. ")
        (custom-parameters 
            (param "TextFade" 0.0
                (at (effect-time 0.0) 0.0)
                (linear (effect-time 2.0) 0.0)
                (linear (effect-time 3.0) 1.0)))
    )
)
]             
}                                                               

See also @secref["title-body-credits-transitions"]