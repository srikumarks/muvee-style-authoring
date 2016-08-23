;muvee-style-authoring.googlecode.com
;muSE v2
;
;   motionlib
;
;   Copyright (c) 2009 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html


;-----------------------------------------------------------
;   Animation curves

(define (log2 n)
  (/ (log n) (log 2)))

(define slow-logarithmic
  (fn (t)
    (* (log2 (+ t 1.0)) t)))

(define fast-logarithmic
  (fn (t)
    (+ (* (log2 (- 2.0 t)) (- t 1.0)) 1.0)))

(define (gompertz b c)
  ; formula:
  ;   f(t) = e^( b * e^(c*t) )
  ; we require b < -8 and c < -10 so that the useful parts
  ; of the curve fall within the unit domain and range
  (fn (t)
    (exp (* b (exp (* c t))))))

(define (underdamped-oscillation z)
  ; formula:
  ;   f(t) = [A cos(wd*t) + B sin(wd*t)] * e^((z-1)*w0*t))
  ;   where    z = [0.1, 1.0],      0.1=critical damping, 1=no damping
  ;         norm = 1/sqrt(z+z-z*z),
  ;           wd = |10*z| * pi,     natural damped frequency
  ;           w0 = wd * norm,       natural undamped frequency
  ;            B = (1-z) * norm,
  ;            A = 1.0
  (let ((norm (pow (- (+ z z) (* z z)) -0.5))
        (wd (* (floor (* 10 z)) pi))
        (w0 (* wd norm))
        (B  (* (- 1.0 z) norm)))
    (fn (t)
      (* (+ (cos (* wd t))
            (* B (sin (* wd t))))
         (exp (* (- z 1.0) w0 t))))))

(define animation-curve-progress
  ; sets up parameters for the animation curve so as to get
  ; points between a and b from progress p0 to p1
  (fn (f p0 a p1 b)
    (let ((tc (linear-tc 0.0 0.0 p0 0.0 p1 1.0 1.0 1.0)))
      (fn (p)
        (+ (* (f (tc p))
              (- b a))
           a)))))

(define (anim:slow p0 a p1 b)
  ; progress is always lagging behind linear
  (animation-curve-progress slow-logarithmic p0 a p1 b))

(define (anim:fast p0 a p1 b)
  ; progress is always rushing ahead of linear
  (animation-curve-progress fast-logarithmic p0 a p1 b))

(define (anim:growth p0 a p1 b)
  (animation-curve-progress (gompertz -8.0 -10.0) p0 a p1 b))

(define ((anim:bounce z) p0 a p1 b)
  ; oscillate about point b, tapering to a halt after 90%
  (let ((bounce (fn (t)
                  (- 1.0 (* ((underdamped-oscillation z) t)
                            (min (- 10.0 (* 10.0 t)) 1.0))))))
    (animation-curve-progress bounce p0 a p1 b)))

(define (anim:bell p0 a p1 b)
  (let ((bell (fn (t) (* (- t 1.0) (- t 1.0) t t 16.0))))
    ; hacking animation-curve-progress function to move
    ; in a bell-shaped path, i.e. from a (at p0) to b (at
    ; mid-point), and then back to a (at p1).
    (animation-curve-progress bell p0 a p1 b)))


;-----------------------------------------------------------
;   Best-fit segment interval

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
;   Motion grid effects

(define make-motion-grid
  (fn (fx vec overlap)
    (let (; deduce number of rows and cols in vec
          (cols (+ (first (sort! (map first vec) -)) 1))
          (rows (+ (first (sort! (map rest vec) -)) 1))
          (gridsize (* cols rows))
          ; normalized start and stop times for cueing fx animation
          (cuepts (fn (idx)
                    (let ((wait (- 1.0 overlap))
                          (span (/ (+ (* (- gridsize 1) wait) 1)))
                          (cue (* wait span idx)))
                      (list (+ cue 0.001) (+ cue span -0.001)))))
          ; coordinates of each grid panel
          (coords (fn ((x . y))
                    (list (/ x cols) (/ (+ x 1) cols)
                          (/ y rows) (/ (+ y 1) rows))))
          ; apply crop and fx to each grid panel
          (layerfx (fn (idx)
                     (let (((p0 p1) (cuepts idx))
                           ((x0 x1 y0 y1) (coords (nth idx vec))))
                       (effect-stack
                         (fx p0 p1 idx x0 y0 x1 y1)
                         (effect "TextureSubset" ()
                                 (input 0 A)
                                 (param "x0" x0)
                                 (param "y0" y0)
                                 (param "x1" x1)
                                 (param "y1" y1)))))))
      ; construct and evaluate layered inputs
      (eval (apply layers
                   (join (list '(A))
                         (map layerfx (enum 0 gridsize))))))))

(define (vectors-ltr n)
  ; generate n coords from left to right
  (map (fn (x) (cons x 0)) (enum 0 n)))

(define (vectors-rtl n)
  ; generate n coords from right to left
  (reverse (vectors-ltr n)))

(define (vectors-btt n)
  ; generate n coords from bottom to top
  (map (fn (y) (cons 0 y)) (enum 0 n)))

(define (vectors-ttb n)
  ; generate n coords from top to bottom
  (reverse (vectors-btt n)))

(define (vectors n . seq)
  (if (< n 2)
    ; just one vector
    (list (cons 0 0))
    ; more than one vector
    (let ((vfn (case seq
                 (('ttb) vectors-ttb)
                 (('btt) vectors-btt)
                 (('rtl) vectors-rtl)
                 (_      vectors-ltr))))
      (vfn n))))

(define vector-sequences
  (shuffled-sequence 'ltr 'rtl 'ttb 'btt))

;;; opacity/plain ;;;

(define opacity-fx
  (fn (dir p0 p1)
    (let (((anim a0 a1) (if (= dir 'in)
                          (list anim:fast 0.0 1.0)
                          (list anim:slow 1.0 0.0))))
      (effect "Alpha" (A)
              (param "Alpha" a0 (anim p0 a0 p1 a1) 30)))))

(define opacity
  (fn (dir)
    (fn (p0 p1 . _)
      (opacity-fx dir p0 p1))))

(define plain
  (fn (dir)
    (make-motion-grid (opacity dir)
                      (vectors 1)
                      1.0)))

;;; yoyo ;;;

(define strips-yoyo
  (fn (dir z)
    (let (((anim z0 z1) (if (= dir 'in)
                          (list (anim:bounce 0.4) z   0.0)
                          (list anim:slow         0.0 z))))
      (fn (p0 p1 . _)
        (effect-stack
          (effect "Translate" (A)
                  (param "z" z0 (anim p0 z0 p1 z1) 30))
          (opacity-fx dir p0 p1))))))

(define yoyo
  (fn (dir)
    (make-motion-grid (strips-yoyo dir (rand 2.0 5.0))
                      (vectors (rand 4 9) (vector-sequences))
                      (rand 0.7 0.8))))

;;; interleave ;;;

(define strips-interleave
  (fn (dir seq)
    (let (((axis len) (if (or (= seq 'btt) (= seq 'ttb))
                        (list "x" (* render-aspect-ratio 2.0))
                        (list "y" 2.0)))
          ((anim tr0 tr1) (if (= dir 'in)
                            (list anim:fast len 0.0)
                            (list anim:slow 0.0 (- len)))))
      (fn (p0 p1 idx . _)
        (let (((tr0# tr1#) (if (= (% idx 2) 0)
                             (list tr0 tr1)
                             (list (- tr0) (- tr1)))))
          (effect-stack
            (effect "Translate" (A)
                    (param axis tr0# (anim p0 tr0# p1 tr1#) 30))
            (opacity-fx dir p0 p1)))))))

(define interleave
  (fn (dir)
    (let ((seq (vector-sequences)))
      (make-motion-grid (strips-interleave dir seq)
                        (vectors (rand 4 9) seq)
                        (rand 0.7 0.8)))))

;;; blinds ;;;

(define rotation-angles
  (shuffled-sequence 'cw 'ccw 'cw 'ccw))

(define strips-blinds
  (fn (dir seq ang)
    (let ((axis (if (or (= seq 'btt) (= seq 'ttb)) "ex" "ey"))
          (deg (if (= ang 'ccw) -450.0 450.0))
          ((anim r0 r1) (if (= dir 'in)
                          (list anim:fast deg 0.0)
                          (list anim:slow 0.0 deg))))
      (fn (p0 p1 _ x0 y0 x1 y1 . _)
        (let ((dx (* (+ x0 x1 -1.0) render-aspect-ratio))
              (dy (+ y0 y1 -1.0)))
          (effect-stack
            (effect "Translate" (A)
                    (param "x" dx)
                    (param "y" dy))
            (effect "Rotate" (A)
                    (param axis 1.0)
                    (param "degrees" r0 (anim p0 r0 p1 r1) 30))
            (effect "Translate" (A)
                    (param "x" (- dx))
                    (param "y" (- dy)))
            (opacity-fx dir p0 p1)))))))

(define blinds
  (fn (dir)
    (let ((seq (vector-sequences))
          (ang (rotation-angles)))
      (make-motion-grid (strips-blinds dir seq ang)
                        (vectors (rand 4 9) seq)
                        (rand 0.7 0.8)))))

;;; spin ;;;

(define horizontal-signs
  (looping-sequence -1  1 1 -1))

(define vertical-signs
  (looping-sequence -1 -1 1  1))

(define plain-spin
  (fn (dir sgnx sgny)
    (let ((dx (* sgnx render-aspect-ratio 4.0))
          (dy (* sgny 2.5))
          (dz -20.0)
          (rx (* sgny -65.0))        ; ensures input faces away from center
          (ry (* sgnx 80.0))         ; when it is near corners, and spins
          (rz (* sgnx sgny -270.0))  ; towards the center of the frame
          ((anim dx0 dx1 dy0 dy1 dz0 dz1 rx0 rx1 ry0 ry1 rz0 rz1)
           (if (= dir 'in)
             (list anim:fast  ; in: anim
                   dx 0.0     ; in: dx0 dx1
                   dy 0.0     ; in: dy0 dy1
                   dz 0.0     ; in: dz0 dz1
                   rx 0.0     ; in: rx0 rx1
                   ry 0.0     ; in: ry0 ry1
                   rz 0.0)    ; in: rz0 rz1
             (list anim:slow       ; out: anim
                   0.0 (- dx)      ; out: dx0 dx1
                   0.0 (- dy)      ; out: dy0 dy1
                   0.0 dz          ; out: dz0 dz1
                   0.0 (- rx)      ; out: rx0 rx1
                   0.0 (- ry)      ; out: ry0 ry1
                   0.0 (- rz)))))  ; out: rz0 rz1
      (fn (p0 p1 . _)
        (effect-stack
          (effect "Translate" (A)
                  (param "x" dx0 (anim p0 dx0 p1 dx1) 30)
                  (param "y" dy0 (anim p0 dy0 p1 dy1) 30)
                  (param "z" dz0 (anim p0 dz0 p1 dz1) 30))
          (effect "Rotate" (A)
                  (param "ex" 1.0)
                  (param "degrees" rx0 (anim p0 rx0 p1 rx1) 30))
          (effect "Rotate" (A)
                  (param "ey" 1.0)
                  (param "degrees" ry0 (anim p0 ry0 p1 ry1) 30))
          (effect "Rotate" (A)
                  (param "ez" 1.0)
                  (param "degrees" rz0 (anim p0 rz0 p1 rz1) 30))
          (opacity-fx dir p0 p1))))))

(define spin
  (fn args
    (let ((sgnx (horizontal-signs))
          (sgny (vertical-signs)))
      (fn (dir)
        (make-motion-grid (plain-spin dir sgnx sgny)
                          (vectors 1)
                          1.0)))))

;;; motion grid with camera movement ;;;

(define camera-move-fx
  (fn (dir)
    (let (((anim ez0 ez1) (if (= dir 'in)
                            (list anim:fast 4.0 0.0)
                            (list anim:slow 0.0 4.0))))
      (effect "LookAt" (A)
              (param "eyez" ez0 (anim 0.1 ez0 0.9 ez1) 30)))))

(define motion-grid-fx
  (fn (min-motion-dur prefx infx outfx postfx)
    (effect-selector
      (fn (start stop inputs)
        (let (((bf-start . bf-stop) (best-fit-segment-interval 0.55 min-motion-dur))
              (actual-fade-dur (min (* (- bf-stop bf-start) 0.5) min-motion-dur))
              (start-fade-in   (- bf-start start))
              (stop-fade-in    (+ start-fade-in actual-fade-dur))
              (stop-fade-out   (- bf-stop start))
              (start-fade-out  (- stop-fade-out actual-fade-dur))
              ((p0 p1 p2 p3) (map (fn (t) (/ t (- stop start)))
                                  (list start-fade-in stop-fade-in
                                        start-fade-out stop-fade-out))))
          (effect-stack
            (remap-time 0.0 p0 prefx)
            (remap-time p0  p1 infx)
            (remap-time p2  p3 outfx)
            (remap-time p3 1.0 postfx)))))))


;-----------------------------------------------------------
;   Video wall transition

(define make-video-wall-transition
  (fn (x y gap% src dst layoutfn camerafx)
    (let ((nx (trunc (max 1 x)))  ; sanitize x to positive integers
          (ny (trunc (max 1 y)))  ; sanitize y to positive integers
          (nxy (* nx ny))  ; maximum number of inputs
          (nsrc (trunc ((limiter 0 (- nxy 1)) src)))  ; sanitize src
          (ndst (trunc ((limiter 0 (- nxy 1)) dst)))  ; sanitize dst
          (indices (enum 0 nxy))  ; enumerate input indices
          (vectors (map (layoutfn nx ny gap%) indices))  ; transform vectors
          (layerfx (fn (idx)  ; arrange inputs as an nx-by-ny grid
                     (let (((dx dy dz rz . _) (nth idx vectors))
                           (deg (if (and (> rz 0) (!= idx nsrc)) 180.0 0.0))
                           (a-or-b (% (trunc (fabs (- idx nsrc))) 2))
                           (ip (cond ((= idx nsrc) A)  ; force nsrc to input A
                                     ((= idx ndst) B)  ; force ndst to input B
                                     ((= a-or-b 1) B)  ; interleave inputs
                                     (_otherwise_  A))))
                       (effect-stack
                         (effect "Translate" (A)
                                 (param "x" dx)
                                 (param "y" dy)
                                 (param "z" dz))
                         (effect "Rotate" ()
                                 (input 0 ip)
                                 (param "ez" 1.0)
                                 (param "degrees" deg)))))))
      (assert (!= nsrc ndst))
      (transition-stack
        ; camera movement from nsrc to ndst
        (camerafx (nth nsrc vectors) (nth ndst vectors))
        ; construct and evaluate layered inputs
        (eval (apply layers
                     (join (list '(A B))
                           (map layerfx indices))))))))

;;; layouts ;;;

(define center-offset
  (fn (idx num gap% len)
    (* (+ idx idx (- num) 1.0)
       (+ gap% 1.0)
       len)))

(define flat-linear-layout
  (fn (x y gap%)
    (fn (idx)
      (let ((ix (% idx x))           ; convert to col index
            (iy (trunc (/ idx x))))  ; convert to row index
        (list (center-offset ix x gap% render-aspect-ratio)  ; dx
              (center-offset iy y gap% 1.0)                  ; dy
              0.0                                            ; dz
              0)))))

(define random-flip-varying-depth-array-layout
  (fn (x y gap%)
    (fn (idx)
      (let ((ix (% idx x))           ; convert to col index
            (iy (trunc (/ idx x))))  ; convert to row index
        (list (center-offset ix x gap% render-aspect-ratio)  ; dx
              (center-offset iy y gap% 1.0)                  ; dy
              (rand -2.0 2.0)                                ; dz
              (rand 2))))))                                  ; rz

;;; roll with camera movement ;;;

(define horizontal/vertical-source/destination-params
  (looping-sequence () ()
                    T  T
                    () T
                    T  ()))

(define to-reverse-or-not-to-reverse?
  (fn (lst)
    (if (horizontal/vertical-source/destination-params)
      (reverse lst)
      lst)))

(define camera-roll-fx
  (fn ((sdx sdy sdz . s_) (ddx ddy ddz . d_))
    (let ((sdz- (- sdz 1.0))
          (ddz- (- ddz 1.0)))
      (effect "LookAt" (A)
              (param "centerx" sdx (anim:growth 0.15 sdx 1.0 ddx) 30)
              (param "centery" sdy (anim:growth 0.15 sdy 1.0 ddy) 30)
              (param "centerz" sdz- (anim:growth 0.15 sdz- 1.0 ddz-) 30)
              (param "eyex" sdx (anim:growth 0.15 sdx 1.0 ddx) 30)
              (param "eyey" sdy (anim:growth 0.15 sdy 1.0 ddy) 30)
              (param "eyez" sdz (anim:bell 0.0 sdz 0.9 (+ sdz 2.5)) 30)))))

(define roll-through-inputs-tx
  (effect-selector
    (fn args
      (let ((pad 1)  ; number of extra inputs to add beyond src and dst
            (dst (+ (* (rand 3) 2) 3))  ; dst is odd {3,5,7} inputs away to ensure better interleaving
            (n (+ pad 1 dst pad))  ; total number of inputs to generate
            (xy (to-reverse-or-not-to-reverse? (list 1 n)))  ; horizontal or vertical
            (sd (to-reverse-or-not-to-reverse? (list pad (+ pad dst)))))  ; forward or reverse
        (make-video-wall-transition (nth 0 xy) (nth 1 xy) 0.05
                                    (nth 0 sd) (nth 1 sd)
                                    flat-linear-layout
                                    camera-roll-fx)))))

;;; fly with camera movement ;;;

(define camera-fly-fx
  (fn ((sdx sdy sdz . s_) (ddx ddy ddz drz . d_))
    (let ((sdz- (- sdz 1.0))
          (ddz- (- ddz 1.0)))
      (effect "LookAt" (A)
              (param "centerx" sdx (bezier 1.0 ddx sdx ddx))
              (param "centery" sdy (bezier 1.0 ddy sdy ddy))
              (param "centerz" sdz- (bezier 1.0 ddz- sdz- ddz-))
              (param "eyex" sdx (bezier 1.0 ddx (- (* sdx 0.5)) (* ddx 0.5)))
              (param "eyey" sdy (bezier 1.0 ddy (- (* sdy 0.5)) (* ddy 0.5)))
              (param "eyez" sdz (bezier 1.0 ddz 40.0 20.0))  ; equivalent height z=7.7
              (cond ((> drz 0)
                     (let ((sign (- (* (rand 2) 2) 1.0)))
                       (param "upx" 0.0 (fn (p) (* (sin (* pi p)) sign)))
                       (param "upy" 1.0 (fn (p) (cos (* pi p)))))))))))

(define fly-across-inputs-tx
  (effect-selector
    (fn args
      (let ((row (+ (* (rand 2) 2) 3))  ; odd number {3,5} to ensure better interleaving
            (col (rand 3 7))
            (idx (shuffle (vector->list (apply vector (enum 0 (* row col)))))))
        (make-video-wall-transition row col 0.15
                                    (nth 0 idx) (nth 1 idx)  ; this ensures src and dst don't clash
                                    random-flip-varying-depth-array-layout
                                    camera-fly-fx)))))
