;muSE v2.0
;
; S10000_BasicEditing_Stage4
;
; A style demonstrating basic editing settings that you can 
; specify as a style author. 

; =================================================================
; STAGE 1 : Starting from the S10000_BlankTemplate
; STAGE 2 : Playing around with editing pace.
; STAGE 3 : Better PACE control
; STAGE 4 : Making the editing pattern respond to music.
;
; We use the "segment duration scaling factor transfer curve"
; to say how we want the editing pace to vary with changes
; in the energy level of the music. We generally want the
; cutting speed to be fast when the music's energy is high
; and slow when the music is soft.
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

; The music energy level value (aka "loudness") is in the range
; 0.0 to 1.0. The left column of numbers specifies various points
; in this range and the right column specifies the corresponding
; scaling factors that we wish to use for these points. Intermediate
; values are determined by linear interpolation. 
;
; The table given here is a fairly straightforward translation of
; the intent described in the "STAGE 4" comment above. However,
; you'll want to play around with this table to get to the kind
; of editing behaviour that you personally like.
(segment-duration-tc 0.0   6.0
                     0.5   1.0
                     1.0   0.25)
