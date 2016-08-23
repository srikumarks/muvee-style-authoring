;muvee-style-authoring.googlecode.com
;muSE v2
;
;   S00514_UltraPlain
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html

(style-parameters
  (one-of-few	TRANSITIONS	Cuts	(Cuts  Dissolves)))

(title-section
  (text
    (font "-22,0,0,0,400,0,0,0,0,3,2,1,34,Arial")
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(credits-section
  (text
    (font "-22,0,0,0,400,0,0,0,0,3,2,1,34,Arial")
    (soft-shadow  dx: 0.0  dy: 0.0  size: 4.0)))

(segment-durations 8.0)

(define dissolves? (= TRANSITIONS 'Dissolves))
(define dissolve-tx (effect "CrossFade" (A B)))

(when dissolves?
  (preferred-transition-duration 2.0)
  (muvee-title-body-transition dissolve-tx 2.0)
  (muvee-body-credits-transition dissolve-tx 2.0))

(define muvee-transition
  (if dissolves? dissolve-tx cut))

(define muvee-segment-effect muvee-std-segment-captions)

;Music Descriptors Debugging code. 
;Uncomment the line below to activate the music descriptors
;(define muvee-global-effect visualMusicDescriptors)
