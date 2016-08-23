;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00538_LifeStory
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Style parameters

(style-parameters
  (continuous-slider	AVERAGE_SPEED	0.375	0.0  0.75)
  (continuous-slider	VARIATION	0.5	0.0  1.0)
  (continuous-slider	BRIGHTNESS	0.5	0.0  1.0)
  (one-of-few		COLOR_START	Color	(Color  BW))
  (one-of-few		COLOR_END	Color	(Color  BW)))


;-----------------------------------------------------------
;   Music pacing

(load (library "pacing.scm"))

(pacing:proclassic AVERAGE_SPEED 0.5)


;-----------------------------------------------------------
;   Global definitions

(define FOVY 30.0)

(define USER_MEDIA_OFFSET -1.0)

(define BRIGHTNESS_FACTOR (* BRIGHTNESS BRIGHTNESS 4.0))

(define best-fit-segment-interval
  ; description:
  ;   marks out the best-fit interval in the segment
  ; parameters:
  ;   * overlap% - sets how much the preferred
  ;   interval extends outside the non-overlapping
  ;   segment interval
  ;   * min-dur - minimum preferred interval
  ; notes:
  ;   under extreme cases, especially when the segment
  ;   is too short, it is impossible to satisfy both
  ;   the overlap and minimum interval criteria, and
  ;   in such cases, fitting into the segment duration
  ;   takes precedence over satisfying the minimum
  ;   interval criteron, followed by overlap criterion
  ;   (if the remaining duration allows for it.)
  ; return value:
  ;   (bestfit-start . bestfit-stop)
  (fn (overlap% min-dur)
    (let (; get the start and stop times of current segment
          (seg-idx   (segment-index))
          (seg-start (segment-start-time))
          (seg-stop  (segment-stop-time))
          (seg-dur   (- seg-stop seg-start))
          ; get the start and stop times where current segment
          ; is non-overlapping with neighbouring segments
          (pure-start (if (> seg-idx 0)
                        (segment-stop-time (- seg-idx 1))
                        seg-start))
          (pure-stop  (if (< seg-idx muvee-last-segment-index)
                        (segment-start-time (+ seg-idx 1))
                        seg-stop))
          (pure-dur   (- pure-stop pure-start))
          ; interpolate between "pure" and "full" segment durations
          ; to get the preferred interval, as set by overlap% param
          (pref-dur  ((linear-tc 0.0 pure-dur 1.0 seg-dur) overlap%))
          ; but when segment is too short, the preferred interval
          ; extends outside the non-overlapping segment interval.
          ; In such cases, we have to make compromises to get the
          ; best-fit interval, which *must* be shorter than or
          ; equal to the segment duration, and *should* be longer
          ; than or equal to the minimum duration whenever possible.
          ; Hence: min-dur <= bestfit-dur <= seg-dur
          (bestfit-dur  (min (max pref-dur min-dur) seg-dur))
          ; under normal circumstances, the bestfit interval is
          ; centrally aligned to the segment interval, however on
          ; the first segment, we align the bestfit start interval
          ; to the segment start time, leaving no gaps at start;
          ; and similarly on the last segment, we align it to the
          ; segment end time, leaving no gaps at the end.
          (bestfit-gap  (* (- seg-stop seg-start bestfit-dur)
                           (cond ((= seg-idx muvee-last-segment-index) 1)
                                 ((= seg-idx 0) 0)
                                 (_ 0.5))))
          ; finally the bestfit interval can be calculated
          (bestfit-start (+ seg-start bestfit-gap))
          (bestfit-stop  (+ bestfit-start bestfit-dur)))
      ; construct best-fit interval as return value,
      ; where: seg-start <= bestfit-start <= pure-start
      ;        <= pure-stop <= bestfit-stop <= seg-stop
      (cons bestfit-start bestfit-stop))))


;-----------------------------------------------------------
;   Global effects

(define muvee-global-effect
  (effect-stack
    (effect "CropMedia" (A))
    (effect "Perspective" (A)
            (param "fovy" FOVY))))


;-----------------------------------------------------------
;   Segment effects
;   - blurred-zoomed-grayscale
;   - move/rotate
;   - 3-D hover
;   - normal fade in and out
;   - grid fade in, normal fade out
;   - color fade from start to end
;   - captions

;;; foreground movement ;;;

(define hover-fx
  (fn args
    (if (<= VARIATION 0.0)
      blank
      (let ((degvar (fn (n) (* (rand (* VARIATION n 0.5) (* VARIATION n))
                               (- (rand 0 2) 0.5) 2.0)))
            (rx (degvar 24.0))
            (ry (degvar 40.0))
            (rz (degvar 12.0)))
        (effect-stack
          (effect "Translate" (A)
                  (param "z" USER_MEDIA_OFFSET))
          (effect "Rotate" (A)
                  (param "ex" 1.0)
                  (param "degrees" (- rx) (linear 1.0 rx)))
          (effect "Rotate" (A)
                  (param "ey" 1.0)
                  (param "degrees" (- ry) (linear 1.0 ry)))
          (effect "Rotate" (A)
                  (param "ez" 1.0)
                  (param "degrees" (- rz) (linear 1.0 rz)))
          (effect "Translate" (A)
                  (param "z" (- USER_MEDIA_OFFSET))))))))

(define rotate-fx
  (fn (dir)
    (let ((deg (if (= (% dir 2) 1) -5.0 5.0)))
      (effect "Rotate" (A)
              (param "ez" 1.0)
              (param "degrees" (- deg) (linear 1.0 deg))))))

(define move-horizontally-fx
  (fn (dir)
    (let ((vec (if (= (% dir 2) 1) -0.25 0.25)))
      (effect "Translate" (A)
              (param "x" (- vec) (linear 1.0 vec))))))

(define move-vertically-fx
  (fn (dir)
    (let ((vec (if (= (% dir 2) 1) -0.18 0.18)))
      (effect "Translate" (A)
              (param "y" (- vec) (linear 1.0 vec))))))

;;; foreground fading in/out ;;;

(define deduce-grid-size
  ; finds the biggest numbers in the list of coordinates
  (fn (vectors)
    (cons (+ (first (sort! (map first vectors) -)) 1)
          (+ (first (sort! (map rest vectors) -)) 1))))

(define enumerate-integers
  ; creates a list of integers from low to high, inclusive
  (fn (low high)
    (if (> low high)
      ()
      (cons low (enumerate-integers (+ low 1) high)))))

(define enumerate-grid-intervals
  ; creates a list with specified number of equal intervals
  (fn (index width)
    (let ((i (- index 1)))
      (if (< i 0)
        ()
        (cons (cons (* i width) (* index width))
              (enumerate-grid-intervals i width))))))

(define enumerate-grid-effects
  ; applies effects to each list element corresponding to each grid panel
  (fn (fx dur% coords cues)
    (if (or (= coords ()) (= cues ()))
      ()
      (cons (fx dur% (first coords) (first cues))
            (enumerate-grid-effects fx dur% (rest coords) (rest cues))))))

(define make-grid-effects
  (fn (fx vectors)
    (let (((cols . rows) (deduce-grid-size vectors))
          (gridsize (* cols rows))
          (thecols (reverse (enumerate-grid-intervals cols (/ cols))))
          (therows (reverse (enumerate-grid-intervals rows (/ rows))))
          (indices (enumerate-integers 0 (- gridsize 1)))

          ; converts grid vectors to normalized coordinates
          (coords-fn (fn ((x . y))
                       (let (((x0 . x1) (nth x thecols))
                             ((y0 . y1) (nth y therows)))
                         (list x0 y0 x1 y1))))
          ; determine the "effect trail" duration per grid panel
          (dur% (- 0.6 (* 0.05 rows)))  ; where rows={2,3,4,5,6,7,8}
          ; calculate progress cue point for a grid panel to show up
          (cue-fn (fn (idx) (* (/ (- 1.0 dur%) (- gridsize 1)) idx)))
          ; shuffle vectors elements
          (vectors# (shuffle vectors)))
      
      ; apply effect to each of the grid panels
      (enumerate-grid-effects fx dur%
                              (map coords-fn vectors#)
                              (map cue-fn indices)))))

(define g2x2
  (list (0 . 1) (1 . 1)
        (0 . 0) (1 . 0)))

(define g3x3
  (list (0 . 2) (1 . 2) (2 . 2)
        (0 . 1) (1 . 1) (2 . 1)
        (0 . 0) (1 . 0) (2 . 0)))

(define g4x4
  (list (0 . 3) (1 . 3) (2 . 3) (3 . 3)
        (0 . 2) (1 . 2) (2 . 2) (3 . 2)
        (0 . 1) (1 . 1) (2 . 1) (3 . 1)
        (0 . 0) (1 . 0) (2 . 0) (3 . 0)))

(define grid-sequence
  (let ((seq$ (apply shuffled-sequence '(g2x2 g3x3 g4x4))))
    (fn args (eval (seq$)))))  ; delayed evaluation

(define texture-subset-fx
  (fn (x0 y0 x1 y1)
    (effect "TextureSubset" (A)
            (param "x0" x0)
            (param "y0" y0)
            (param "x1" x1)
            (param "y1" y1))))

(define fade-in-fx
  (fn (p1 p2)
    (effect "Alpha" (A)
            (param "Alpha" 0.0 (at p1 0.0) (bezier p2 1.0 0.0 1.0)))))

(define per-grid-fade-in
  (fn (dur% coords cue)
    (list 'effect-stack
          (cons 'texture-subset-fx coords)
          (list 'with-inputs '(list A)
                (list 'fade-in-fx cue (+ cue dur%))))))

(define make-grid-layers
  (fn (seq)
    (eval (apply layers
                 (append! (list '(A))
                          (make-grid-effects per-grid-fade-in seq))))))

(define grid-fade-fx
  (fn (start stop inputs)
    (let ((pref-fade-dur 1.5)
          ((bf-start . bf-stop) (best-fit-segment-interval 0.65 pref-fade-dur))
          (actual-fade-dur    (min (* (- bf-stop bf-start) 0.5) pref-fade-dur))
          (rel-start-fade-in  (- bf-start start))
          (rel-stop-fade-out  (- bf-stop start))
          (rel-start-fade-out (- rel-stop-fade-out actual-fade-dur))
          ; the grid fade-in effect
          (grid-fx (make-grid-layers (grid-sequence)))
          (thegrid (grid-fx bf-start (+ bf-start actual-fade-dur) inputs)))
      ((effect "Alpha" (A)
               (param "Alpha" 0.0
                      (at     (effect-time (+ rel-start-fade-in  0.01)) 1.0 0.0 1.0)
                      (at     (effect-time (+ rel-start-fade-out 0.01)) 1.0)
                      (bezier (effect-time (+ rel-stop-fade-out -0.01)) 0.0 1.0 0.0)
                      (at 1.0 0.0)))
       start stop (list thegrid)))))

(define normal-fade-fx
  (fn (start stop inputs)
    (let ((pref-fade-dur 2.0)
          ((bf-start . bf-stop) (best-fit-segment-interval 0.5 pref-fade-dur))
          (actual-fade-dur    (min (* (- bf-stop bf-start) 0.5) pref-fade-dur))
          (rel-start-fade-in  (- bf-start start))
          (rel-stop-fade-in   (+ rel-start-fade-in actual-fade-dur))
          (rel-stop-fade-out  (- bf-stop start))
          (rel-start-fade-out (- rel-stop-fade-out actual-fade-dur)))
      ((effect "Alpha" (A)
               (param "Alpha" 0.0
                      (at     (effect-time (+ rel-start-fade-in  0.01)) 0.0)
                      (bezier (effect-time (+ rel-stop-fade-in  -0.01)) 1.0 0.0 1.0)
                      (at     (effect-time (+ rel-start-fade-out 0.01)) 1.0)
                      (bezier (effect-time (+ rel-stop-fade-out -0.01)) 0.0 1.0 0.0)
                      (at 1.0 0.0)))
       start stop inputs))))

;;; segment effect selector ;;;

(define random-fade-in
  (shuffled-sequence grid-fade-fx
                     normal-fade-fx
                     normal-fade-fx
                     normal-fade-fx))

(define random-foreground-fx
  (shuffled-sequence (rotate-fx 0)
                     (rotate-fx 1)
                     (move-horizontally-fx 0)
                     (move-horizontally-fx 1)
                     (move-vertically-fx 0)
                     (move-vertically-fx 1)))

(define grayscale-fpstr (format "!!ARBfp1.0
PARAM luma = { 0.299, 0.587, 0.114, 1.0 };
TEMP texfrag, gray;
TEX texfrag, fragment.texcoord[0], texture[0], 2D;
MUL texfrag.a, texfrag.a, fragment.color.a;
DP3 gray.r, texfrag, luma;
MUL gray.r, gray.r, " BRIGHTNESS_FACTOR ";
MOV gray.a, texfrag.a;
SWZ result.color, gray, r,r,r,a;
END"))

(define blurred-zoomed-grayscale-fx
  (fn (blur zoom flipx?)
    (effect-stack
      (effect "BlurLayers" (A)
              (param "NumberOfLayers" 3)
              (param "LayerAlpha" 0.2)
              (param "LayerOffset" 0.05)
              (param "LevelOfDetail" 0.0))
      (effect "Blur" (A)
              (param "Amount" blur))
      (effect "FragmentProgram" (A)
              (param "GlobalMode" 1)
              (param "ProgramString" grayscale-fpstr))
      (effect "Scale" (A)
              (param "x" (* (if (= flipx? 0) 1.0 -1.0) zoom))
              (param "y" zoom)))))

(define color-from-start-to-end-fx
  (fn (start stop inputs)
    (let ((alpha-start (if (= COLOR_START 'BW) 0.0 1.0))
          (alpha-stop  (if (= COLOR_END 'BW) 0.0 1.0))
          (alpha-tc (linear-tc 0.0 alpha-start 1.0 alpha-stop))
          (a0 (alpha-tc (/ start muvee-duration-secs)))
          (a1 (alpha-tc (/ stop muvee-duration-secs))))
      ((effect "FragmentProgram" (A)
               (param "GlobalMode" 1)
               (param "ProgramString" RGBtoYUV)
               (param "NumParams" 2)
               (param "r1" 1.0)
               (param "g1" a0 (bezier 1.0 a1 a0 a1))
               (param "b1" a0 (bezier 1.0 a1 a0 a1)))
       start stop inputs))))

(define translate-input-behind-and-scale-up-fx
  (fn (delta-z)
    (let ((tangent (tan (deg->rad (* FOVY 0.5))))
          (scale (- 1.0 (* tangent delta-z))))
      (effect-stack
        (effect "Translate" (A)
                (param "z" delta-z))
        (effect "Scale" ()
                (input 0 A)
                (param "x" scale)
                (param "y" scale))))))

(define view-fx
  (fn args
    (effect-stack
      (effect "Alpha" (A)
              (param "Alpha" 0.999))
      (layers (A)
        ; background
        (effect-stack
          (blurred-zoomed-grayscale-fx 4.0 (rand 2.0 4.0) (rand 0 2))
          (translate-input-behind-and-scale-up-fx -4.0))
        ; foreground
        (effect-stack
          (random-fade-in)
          (hover-fx)
          (random-foreground-fx)
          color-from-start-to-end-fx
          (effect "Translate" (A)
                  (param "z" USER_MEDIA_OFFSET))
          muvee-std-segment-captions
          (effect "Alpha" ()
                  (input 0 A)))))))

(define muvee-segment-effect
  (effect-selector view-fx))


;-----------------------------------------------------------
;   Transitions
;   - crossfade
;   - fade-to-black

(define dissolve-tx
  (let ((a 2.0))
    (layers (A B)
      (effect-stack
        (effect "Translate" (A)
                (param "z" -0.001))
        (effect "Alpha" ()
                (input 0 A)
                (param "Alpha" 1.0
                       (fn (p) (- 1.0 (pow p a))))))
      (effect "Alpha" ()
              (input 0 B)
              (param "Alpha" 0.0
                     (fn (p) (- 1.0 (pow (- 1.0 p) a))))))))

(define fade-to-black-tx
  (layers (A B)
    ; show input A for first half of effect
    (effect "Alpha" ()
            (input 0 A)
            (param "Alpha" 1.0 (at 0.5 0.0)))
    ; show input B for second half of effect
    (effect "Alpha" ()
            (input 0 B)
            (param "Alpha" 0.0 (at 0.5 1.0)))
    ; color fade in and fade out
    (effect-stack
      (effect "Translate" (A)
              (param "z" 0.001))
      (effect "ColorQuad" ()
              (param "a" 0.0
                     (bezier 0.5 1.0 0.0 0.0)
                     (bezier 1.0 0.0 1.0 1.0))
              (param "r" 0.0)
              (param "g" 0.0)
              (param "b" 0.0)))))

(define muvee-transition
  (effect-selector
    (shuffled-sequence fade-to-black-tx
                       dissolve-tx
                       dissolve-tx
                       dissolve-tx)))


;-----------------------------------------------------------
;   Title and credits

(define BACKGROUND_IMAGE
  (format (if (< (fabs (- render-aspect-ratio 4/3)) 0.1) "4-3" "16-9")
          "_background.jpg"))

(define title/credits-view-fx
  (fn (foreground-fx)
    (effect-stack
      (effect "CropMedia" (A))
      (effect "Perspective" (A)
            (param "fovy" FOVY))
      (effect "Alpha" (A)
              (param "Alpha" 0.999))
      (layers (A)
        ; background
        (effect-stack
          (blurred-zoomed-grayscale-fx 4.0 1.8 0)
          (translate-input-behind-and-scale-up-fx -4.0))
        ; foreground
        (effect-stack
          foreground-fx
          (effect "FragmentProgram" ()
                  (input 0 A)
                  (param "GlobalMode" 1)
                  (param "ProgramString" RGBtoYUV)
                  (param "NumParams" 2)
                  (param "r1" 1.0)
                  (param "g1" 1.0)
                  (param "b1" 1.0)))))))

(define TITLE_FOREGROUND_FX
  (title/credits-view-fx
    (effect-stack 
      (effect "Translate" (A)
              (param "z" 0.0
                     (bezier 0.8 USER_MEDIA_OFFSET 0.0 USER_MEDIA_OFFSET)))
      (effect "Alpha" (A)
              (param "Alpha" 1.0
                     (at 0.5 1.0)
                     (bezier 0.8 0.0 1.0 0.0))))))

(define CREDITS_FOREGROUND_FX
  (title/credits-view-fx
    (effect-stack
      (effect "Translate" (A)
              (param "z" USER_MEDIA_OFFSET
                     (at 0.13 USER_MEDIA_OFFSET)
                     (bezier 0.65 0.0 USER_MEDIA_OFFSET 0.0)))
      (effect "Alpha" (A)
              (param "Alpha" 0.0
                     (at 0.13 0.0)
                     (bezier 0.32 1.0 0.0 1.0)
                     (at 1.0 1.0))))))

(title-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx TITLE_FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-out)
    (font "-22,0,0,0,800,1,0,0,0,3,2,1,34,Georgia")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 2.0)))

(credits-section
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx CREDITS_FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color 255 255 255)
    (fade-in)
    (font "-22,0,0,0,800,1,0,0,0,3,2,1,34,Georgia")
    (layout (0.10 0.10) (0.90 0.90))
    (soft-shadow  dx: 0.0  dy: 0.0  size: 2.0)))

;;; transitions between title/credits and body ;;;

(define title/credits-tx-dur
  ; ranges from 0.5 to 3.0 seconds
  (+ (* (- 1.0 AVERAGE_SPEED) 2.5) 0.5))

(muvee-title-body-transition dissolve-tx title/credits-tx-dur)

(muvee-body-credits-transition dissolve-tx title/credits-tx-dur)
