#lang scribble/doc
@(require scribble/manual scribble/decode)

@title[#:style 'toc]{List of primitive effects and transitions}

@(define (fxlist . names)
   (let [(sorted-names (sort names string<?))]
     (make-splice
      (apply append 
             (cons (list "" (secref (car sorted-names)))
                   (map (lambda (n) (list ", " (secref n)))
                        (cdr sorted-names)))))))

@subsubsub*section{Geometry}
@fxlist[
        "Alignment" 
        "LookAt"
        "Perspective"
        "Reflect"
        "Rotate"
        "Scale"
        "Translate"
        ]

@subsubsub*section{Common}
@fxlist[
        "CropMedia"
        "GradientFade"
        "GradientFade_ColorBorder"
        "PictureQuad"
        "RapidOverlay"
        "SeamlessBackground"
        "TextOut"
        "TextureSubset"
        ]

@subsubsub*section{Color}
@fxlist[
        "Alpha"
        "ColorQuad"
        "ColorMapRGB"
        "ColorSelect"
        "CrossFade"
        "Desaturate"
        "Greyscale"
        "RGBtoYUV"
        "Saturate"
        "Sepia"
        ]

@subsubsub*section{Image processing}
@fxlist[
        "Blur"
        "BlurLayers"
        "Distort"
        "HeightMap"
        "Mask"
        "RadialBlur"
        ]

@subsubsub*section{OpenGL}
@fxlist[
        "Cg"
        "FragmentProgram"
        "Light"
        "Material"
        "VertexProgram"
        ]

@subsubsub*section{Special effects}
@fxlist[
        "Flip"
        "MovingPolygons"
        "OldMovieLines"
        "OldMovieScratches"
        "PageCurl"
        "ReflectAndRipples"
        "Shatter"
        "Snow"
        "VolumetricLights"
        ]

@include-section["alignment.scrbl"]
@include-section["alpha.scrbl"]
@include-section["blur.scrbl"]
@include-section["blurLayers.scrbl"]
@include-section["Cg.scrbl"]
@include-section["color-quad.scrbl"]
@include-section["colorMapRGB.scrbl"]
@include-section["colorSelect.scrbl"]
@include-section["crop-media.scrbl"]
@include-section["cross-fade.scrbl"]
@include-section["desaturate.scrbl"]
@include-section["distort.scrbl"]
@include-section["flip.scrbl"]
@include-section["fragmentProgram.scrbl"]
@include-section["gradientFade.scrbl"]
@include-section["gradientFade_ColorBorder.scrbl"]
@include-section["greyscale.scrbl"]
@include-section["heightMap.scrbl"]
@include-section["light.scrbl"]
@include-section["lookAt.scrbl"]
@include-section["mask.scrbl"]
@include-section["material.scrbl"]
@include-section["movingPolygons.scrbl"]
@include-section["oldMovieLines.scrbl"]
@include-section["oldMovieScratches.scrbl"]
@include-section["pageCurl.scrbl"]
@include-section["perspective.scrbl"]
@include-section["picture-quad.scrbl"]
@include-section["radialBlur.scrbl"]
@include-section["rapidOverlay.scrbl"]
@include-section["reflect.scrbl"]
@include-section["reflectAndRipples.scrbl"]
@include-section["rgbToYUV.scrbl"]
@include-section["rotate.scrbl"]
@include-section["saturate.scrbl"]
@include-section["scale.scrbl"]
@include-section["seamlessBackground.scrbl"]
@include-section["sepia.scrbl"]
@include-section["shatter.scrbl"]
@include-section["snow.scrbl"]
@include-section["textOut.scrbl"]
@include-section["texture-subset.scrbl"]
@include-section["translate.scrbl"]
@include-section["vertexProgram.scrbl"]
@include-section["volumetricLights.scrbl"]

                
                 

