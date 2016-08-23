#lang scribble/doc
@(require scribble/manual scribble/struct "effect-parameter-table.ss")

@title[#:style 'quiet]{LookAt}

There are two distinct ways of making things move in our 3D world. One way is to move the actual pictures around the screen using the @link["http://muvee-style-authoring.googlecode.com/svn/doc/main/Translate.html"]{Translate} effect. The other way is to move our virtual camera around (yup, we got a camera yo!). A good way to conceptualize this is to treat all of what we see on the screen as being recorded on a camera. So this effect actually allows us to move our camera/eye around in our 3D world.

@effect-parameter-table[
                        [eyex 0.0 @list{n/a} @list{x coordinate of the position of the camera/eye.}]
                        [eyey 0.0 @list{n/a} @list{y coordinate of the position of the camera/eye.}]
                        [eyez 0.0 @list{n/a} @list{z coordinate of the position of the camera/eye.}]                        
                        [centerx  0.0 @list{n/a} @list{x coordinate of the point the camera camera/eye is looking at.}]
                        [centery -1.0 @list{n/a} @list{y coordinate of the point the camera camera/eye is looking at.}]
                        [centerz  0.0 @list{n/a} @list{y coordinate of the point the camera camera/eye is looking at.}]
                        [upx 0.0 @list{n/a} @list{x component of the normalized vector that defines the "up" orientation.}] 
                        [upx 0.0 @list{n/a} @list{y component of the normalized vector that defines the "up" orientation.}]
                        [upx 0.0 @list{n/a} @list{z component of the normalized vector that defines the "up" orientation.}]

                        ]


@input-and-imageop[(A) "No."]



@section{Examples}

@subsection{Camera motion example.}


@schemeblock[
(code:comment "muSE v2")
(code:comment "")
(code:comment "My good-looking style.")
(code:comment "This style changes the position and orientation of the viewing camera.")

(style-parameters)

(segment-durations 8.0)

(define muvee-global-effect (effect-stack
				 (effect "CropMedia" (A))
				 (effect "Perspective" (A))))

(define muvee-segment-effect (effect "LookAt" (A)
                                     (param "eyez" 0.0 (linear 1.0 1.0))
                                     (param "upy" 1.0 (at 0.5 -1.0))
                                     (param "centerx" 0.0 (linear 1.0 1.0))))

]

This is an example that's doing some funky stuff with our camera. The @scheme[eyez] parameter is animated to move from 0.0 to 1.0 for the whole duration. What that really means is we are moving our camera along the positive z-axis. But since our picture is placed by default at @scheme[z = -2.14], the net impression will be that our picture in moving away from us. The second parameter inverts the @scheme[upy] at progress = 0.5 (which is basically in the middle of a segment). So the net effect to us will be a sudden image inversion in the middle of each segment. Finally @scheme[centerx] goes from 0.0 to 1.0 during the duration of the segment. The net effect will be that our picture will appear to be rotating along the y-axis. Do note that in real terms, our picture is not moving at all, we are only moving the camera.  Refer to @seclink["explicit-animation-curves"]{Explicit animation curves} for more info on how we animate the parameters.

@image["image/lookAt.jpg"]





