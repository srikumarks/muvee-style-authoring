;muSE v2.0
;
; S10000_BasicEditing_Stage5
;
; A style demonstrating basic editing settings that you can 
; specify as a style author. 

; =================================================================
; STAGE 1 : Starting from the S10000_BlankTemplate
; STAGE 2 : Playing around with editing pace.
; STAGE 3 : Better PACE control
; STAGE 4 : Making the editing pattern respond to music.
; STAGE 5 : Adding transitions
;
; Up to STAGE 4, we got a production with only cuts in it.
; In this stage, we introduce the cross-fade transition and how
; to specify some transition related attributes.
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

; Convert the logarithmic PACE scale to a factor that we
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
; of editing behaviour that you personally like. The table can be
; as elaborate or as simple as you want it to be.
(segment-duration-tc 0.0   6.0
                     0.5   1.0
                     1.0   0.25)

; --------- Transitions -----------------------------------------------

; We need to tell the constructor our preferred transition
; duration so that it can create the appropriate overlaps
; and select the right amount of material. The duration is
; specified in beats - the same units used for segment-durations
; above.
(preferred-transition-duration 0.4)

; Specify a threshold for the segment duration below which you don't
; want to have transitions, but do cuts instead. This value is usually
; dependent on the the *kind* of transitions used by the style. Some
; styles use long transitions that cannot be shortened very much while
; others use transitions that can be time stretched pretty much
; arbitrarily.
(min-segment-duration-for-transition 0.8)

; Indicate the we want to use the "CrossFade" transition between
; segments. We'll get into the authoring of sophistcated effects
; and transitions in a separate tutorial, so just accept that the
; line below sets up the cross-fade transition to be used between
; consecutive segments.
(define muvee-transition (effect "CrossFade" (A B)))

