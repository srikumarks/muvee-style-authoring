;muSE v2.0
;http://muvee-style-authoring.googlecode.com/svn/trunk/lib/google.scm
;
;   Copyright (c) 2008 muvee Technologies Pte Ltd.
;   All rights reserved.
;   License: http://muvee-style-authoring.googlecode.com/svn/doc/main/License.html
;   "Google" is a trademark of Google Inc.
;
; This "google" module provides a simple interface to query
; google for specific types of results for use within muvee styles.

(module google (referer services search search* fetch-result static-map-uri))

; Google requires us to fill the Referer field of a HTTP request.
; If you're going to use Google's services in your style on a
; large scale, we recommend you modify the referer to your
; own site. The site can be a post about your style on muveeManiacs
; for example. You might also want to get an API key from Google here -
;   http://code.google.com/apis/ajaxsearch/signup.html
;
; You can change the referer after you load this module like this -
;   (google.referer "http://my.web.site.com/subpath")
; Subsequent searches will use the referer URL you set.
(define referer (box "http://muvee-style-authoring.googlecode.com"))

; The symbols that are valid in the "service" argument
; of the search functions. This is simply a list of symbols
; for reference.
(define services '(web local video blogs news books images patent))

; Private function to check a service string or symbol for validity.
; Takes a service as an argument and evaluates to the service if
; it is valid, otherwise raising the google:service-not-available
; condition.
(define validate-service 
  (let ((service-table (hashtable (map (fn (x) (cons x T)) services))))
    (fn (service)
	(if (service-table service)
	    service
	    (raise 'google:service-not-available service)))))


; Private function to compute the standard headers to pass to Google.
(define (headers)
  (list (format "Referer: " (referer))))

; Searches the specified service for the given service symbol
; and returns results starting from the given "start" index.
; The search string has to be url-friendly. For example,
; if you're searching for "michael jackson", you have to
; give the string as "michael+jackson".
;
; See "services" above for valid service symbols.
(define (search service str start)
  (try (do
	   ; fetch-uri will download the search result json expression
	   ; into a local file in the cache.
	   (fetch-uri (format "http://ajax.googleapis.com/ajax/services/search/" 
			      (validate-service service)
			      "?v=1.0"
			      (if start (format "&start=" start) "")
			      "&q=" 
			      str) 
		      (headers))
  
	   ; Read the json object in the file and close it right
	   ; before this function completes.
	   (open-file (the fetch-uri) 'for-reading)
	   (finally (close (the open-file)))

	   ; The result is the read json object.
	   ; A response json usually has one field called "responseData" 
	   ; under which "results" is a vector of result objects.
	   ; The "url" field of a result object gives the link to a
	   ; particular result resource.
	   (read-json (the open-file)))))
	 
; Given a response object or a vector of result objects, 
; "fetch-result" will download the link of the 
; n-th response (n is zero-based).
(define (fetch-result results n)
  (cond
   ((vector? results)
    (if (< n (length results))
	(fetch-uri (get results n 'url) (headers))
	(raise 'google:not-enough-results results n)))
   ((hashtable? results)
    (fetch-result results.responseData.results n))))

; Gives all the results from start to stop in a 
; single vector, making repeated requests if necessary.
; 
; There could be more or fewer results than the given range.
; For example, if you asked for start=0, stop=41, then you
; could get 44 results back or if there aren't that many
; you could get only 3 results.
; 
; More is usually not a problem, but you need to
; account for fewer results.
(define (search* service str start stop)

  ; Gets a list of search result vectors.
  (define (collect-results start stop)

    ; Get a first batch of results from the given start point.
    (define results (get (search service str start) 'responseData 'results))

    ; If we've got enough results, we're done, otherwise
    ; prepare the future result collection calls as a lazy list.
    (if (and (> (length results) 0) 
	     (< (the length) (- stop start)))
	(lcons results (collect-results (+ start (length results)) stop))
	(list results)))

  ; Join all the search results. The result will be a non-lazy vector
  ; with all entries containing valid results objects.
  (apply join (collect-results start stop)))

; (static-map-uri ...) constructs a URI that calls google to construct
; a static png image of the map that can be used for various purposes.
; For documentation about the various parameters, see -
;    http://code.google.com/apis/maps/documentation/staticmaps/#URL_Parameters
; Calling fetch-uri on the resultant URI will download the map image
; to your local cache and give you the file path.
;
; Ignore the dummy=map.png parameter at the end. It exists solely to provide
; a valid file extension to fetch-uri
(define (static-map-uri latitude longitude zoom width height maptype)
  (format "http://maps.google.com/maps/api/staticmap?"
	  "center=" latitude "," longitude
	  "&zoom=" zoom
	  "&size=" width "x" height
	  "&maptype=" maptype
	  "&sensor=false"
	  "&dummy=map.png"))
