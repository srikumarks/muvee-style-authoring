#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{Utility functions}

@section{@scheme[fetch-uri]}

@defproc[(fetch-uri (uri string)) string]{

Downloads the given URI and returns the file path of the downloaded file. A few types of URI mime-types are supported -

@subsubsub*section{@tt{text/xml}}
@indent{Any response to the URL with a MIME type string containing ``xml'' is treated as an XML document
            and labelled with the @filepath{.xml} extension.}

@subsubsub*section{@tt{image/jpeg}, @tt{image/png} and @tt{image/bmp}}
@indent{JPEG and PNG image files are downloaded and given a file path with their respective common file extensions.}

@subsubsub*section{@tt{text/plain}}
@indent{Gets the extension @filepath{.txt}. Scheme files also use the @tt{text/plain} MIME type. So you can load @filepath{.scm} files using -
             @schemeblock[(load (fetch-uri "http://somewhere.com/path/lib.scm"))]
             }

@subsection{Exceptions with @scheme[fetch-uri]}

Whenever you access the network, you should guard yourself against exceptional conditions such as connection failures, transfer interruptions, etc. The @scheme[fetch-uri] function raises a few exceptions to let you know about these conditions so you can respond to them. When these exceptions occur, you can choose to abort the operation or continue with, say, a default file. For details about raising and handling muSE exceptions and about the @scheme[_resume] continuation, refer to the documentation on the @link["http://muvee-symbolic-expressions.googlecode.com"]{muSE project page}.

@subsubsub*section{@scheme[(_resume 'fetch-uri:network-error _uri)]}
@indent{Indicates a fundamental problem with connecting to the internet. You can resume when this exception occurs by choosing to use a fixed local file path instead of the downloaded URI. You can resume like this - @schemeblock[(_resume "somewhere\blah.jpg")]}

@subsubsub*section{@scheme[(_resume 'fetch-uri:bad-resource _uri)]}
@indent{Indicates that the URI is either badly formatted or is referring to an invalid resource. In this case, you can resume by either using a default URI that is known to work, or a fixed local file, using the @scheme[_resume] function.}

@subsubsub*section{@scheme[(_resume 'fetch-uri:unsupported _uri)]}
@indent{Indicates that the URI is not a @tt{http} URI  or is of a type that cannot be supported for some reason. In this case, you're allowed to resume by replacing the URI with a default file.}

@subsubsub*section{@scheme[(_resume 'fetch-uri:cache-failure _uri)]}
@indent{Indicates a problem downloading the URI and storing it in the cache. In this case, you're allowed to replace it with a local file.}

}







