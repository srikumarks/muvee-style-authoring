;muSE v2.0
;
; S10000_BasicEditing_Stage3
;
; A style demonstrating basic editing settings that you can 
; specify as a style author. 

; =================================================================
; STAGE 1 : Starting from the S10000_BlankTemplate
; STAGE 2 : Playing around with editing pace.
; STAGE 3 : Better PACE control
;
; The PACE control implemented in the previous stage doesn't behave 
; very nicely. The pacing varies very fast for the first 1/4 of the
; slider's range and much more slowly for the remaining 3/4. So,
; we change the PACE slider to work on a logarithmic scale so that
; we can make the mid point of the slider correspond to a nominal
; pace with the left extreme end and the right extreme end give us
; 4x the speed and 1/4 the speed respectively.
;
; We use this stage to bring up one issue that is worth a style
; author's attention - the perceptual behaviour of the style
; controls. Ideally, we want the sliders to behave in a perceptually
; linear manner and definitely at least monotonic - meaning
; always increasing something or decreasing something in one
; direction but never both in the same direction.
; =================================================================

; ---------------------------------------------------------------------
; Declare style parameters to be exposed in this style's 
; "Style Settings" panel.

(style-parameters
 ; The PACE slider goes from slow pace to fast pace, with the middle
 ; value corresponding to the default pace. We use 0.0 to denote the
 ; middle value, -ve values to indicate slower pacing and +ve values
 ; to indicate faster pacing. The logarithmic scale suits the intended
 ; behaviour of the PACE slider rather well and we convert the PACE
 ; value to a time scaling factor using formule
 ;    factor = pow(2, PACE)
 (continuous-slider PACE 0.0 -2.0 2.0)
 )

; --------- Editing logic -----------------------------------------------

; Conver the logarithmic PACE scale to a factor that we
; can use to control editing speed.
(define pace-factor (pow 2 PACE))

; Calculate the reference segment duration from the PACE slider.
(define ref-seg-dur (/ 2.0 pace-factor))

; Specify a uniform cutting pattern without any segment variations.
(segment-durations ref-seg-dur)

