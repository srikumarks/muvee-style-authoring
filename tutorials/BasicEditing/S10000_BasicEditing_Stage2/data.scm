;muSE v2.0
;
; S10000_BasicEditing_Stage2
;
; A style demonstrating basic editing settings that you can 
; specify as a style author. 

; =================================================================
; STAGE 1 : Starting from the S10000_BlankTemplate
; STAGE 2 : Playing around with editing pace.
; =================================================================

; ---------------------------------------------------------------------
; Declare style parameters to be exposed in this style's 
; "Style Settings" panel.

(style-parameters
 ; The PACE slider goes from slow pace to fast pace, with the middle
 ; value corresponding to the default pace. We directly control the
 ; preferred segment duration using the PACE value.
 (continuous-slider PACE 2.0 0.5 8.0)
 )

; --------- Editing logic -----------------------------------------------

; Specify a uniform cutting pattern without any segment variations.
(segment-durations PACE)

