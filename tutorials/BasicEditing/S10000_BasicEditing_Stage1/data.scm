;muSE v2.0
;
; S10000_BasicEditing_Stage1
;
; A style demonstrating basic editing settings that you can 
; specify as a style author. Look at the subversion history
; of this data.scm file to examine the various stages of the
; tutorial.

; =================================================================
; STAGE 1 : Starting from the S10000_BlankTemplate
; =================================================================

; We don't use any style parameters for starters.
(style-parameters)

; --------- Editing logic -----------------------------------------------

; Specify a uniform cutting pattern without any segment variations.
; 2.0 is in units of "beats". Its absolute value in seconds depends
; on the music's tempo.
(segment-durations 2.0)
