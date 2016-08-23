#lang scribble/doc
@(require scribble/manual "utils.ss")

@title{A Gentle Introduction to muSE}

muSE stands for @italic{muvee Symbolic Expressions} - a scripting language
used in the specification of muvee Reveal's styles. A style package's
@scheme[data.scm] file is a muSE script that decides what the various aspects
of a style should be.

This document introduces muSE to those who are may not be familiar
with it or the language Scheme on which it is based. It is intended to
be a gentle as well as a quick introduction to the underlying
scripting language.

For detailed information about muSE, see its 
@link["http://muvee-symbolic-expressions.googlecode.com"]{project page}.

We strongly recommend that you use the
@link["http://www.drscheme.org"]{DrScheme} program to view and edit
muSE files. You can use DrScheme to try out the expressions that we
present in this quick tutorial. 

@section{Expressions}

A muSE data file typically ends with the extension @scheme[.scm] for ``Scheme''. However, we like to call them ``scum'' files. A @scheme[scm] file consists of a sequence of muSE @italic{expressions} which are @italic{evaluated} in the order in which they appear. 

An @italic{expression} can be a simple thing such as -
@itemize{
	@item{@bold{simple decimal numbers} : 1, 2, -15, 355, 113, etc.}
	@item{@bold{fractional numbers} : 1.2, 3.1415, -100.0, etc.}
	@item{@bold{hexadecimal numbers} : 0xbabe, 0xF00D, etc.}
	@item{@bold{strings} : @scheme["Hello muSE"], @scheme["Louis sang 'What a wonderful world!'"], etc.}
	@item{@bold{symbols} : @scheme[mumboJumbo], @scheme[MuveeTechnologies], @scheme[nuclear-cockroach], @scheme[dont-sw^%$#-in-code?], etc. Symbols start with a letter and can contain any character other than quotes, brackets, and period.}
	@item{@bold{lists} : A list of items is notated within
	parentheses. For example -
	    @itemize{
	      @item{@scheme[(1 2 3 4 5)]}
	      @item{@scheme[(1 "He" 2 "HeHee" 3 "HeHeHeee")]}
	      @item{@scheme[(Name "Willy Wonka" Age 30 Height 5.8)]}
	      }
	      Lists can consist of simple data such as shown above or
	      consist of other lists. Here is an example of a list
	      that mixes them up - 
@schemeblock[
("List demo" 1 2.34 five 
       (Name "Willy Wonka") 
       (Age 30) 
       (Height 5.8))
]
}
}

@section{Evaluating an expression}

@itemize{
  @item{Simple data values such as numbers and strings evaluate to themselves - i.e. @scheme[3.1415], when it occurs anywhere, always means the same value @scheme[3.1415]}
  @item{Symbols may be defined to other values using the
  @scheme[(define ...)] form like this -
      @schemeblock[(define Name "Willy Wonka")]
      After @italic{evaluating} the above definition, the symbol @scheme[Name] by itself will be replaced by the string @scheme["Willy Wonka"] (without the double quotation marks).}}

@subsection{List expressions}
List expressions are evaluated using a special method - 
@itemize{
  @item{The first item in the list is evaluated to determine an @italic{operator}}
  @item{The operator is then @italic{applied} to the rest of the list in order to derive the value of the expression.}
  }

For example, when
@schemeblock[
(+ 1 2 3 4)
]
is evaluated, the symbol + is interpreted as the operator that performs addition and this addition operator is @italic{applied} to the rest of the list
@schemeblock[
(1 2 3 4)
]
in order to obtain the value 
@schemeblock[
10
]

So the value of the expression @scheme[(+ 1 2 3 4)] is @scheme[10].

The @scheme[_rest-of-the-list] can itself consist of other expressions which are evaluated to determine intermediate values. For example, the expression 
@schemeblock[
(/ (- 100 30) (+ 100 30))
]
computes the value @scheme[(100-30)/(100+30)]. You can determine the result of the above expression using the following sequence of reduction steps -
@schemeblock[
 (/ (- 100 30) (+ 100 30))
 (/ 70 (+ 100 30))
 (/ 70 130)
 0.538462
]

muSE includes a host of built-in operators that perform various computations on their operands. It also includes facilities to define your own operators within muSE itself (see [#Functions] below).

@subsection{Quoted expressions}
If you do not wish to interpret the first item of a list as an operator, you can @scheme[quote] it using the single quote character as follows -
@schemeblock[
'(+ 1 2 3 4)
]
The above is a literal list of 5 items where the first item is the symbol @scheme[+], and the rest of the items are the numbers @scheme[1], @scheme[2], @scheme[3] and @scheme[4] respectively.

You may read the single quote in the above expression as the word ``literally'', so that the above expression becomes -
@schemeblock[
Literally the list of items +, 1, 2, 3, and 4.
]

You can also quote symbols to prevent them from evaluating to their defined values as follows -
@schemeblock[
'pie
]
will always be the symbol @scheme[pie] even if you had defined it to a numerical value like this -
@schemeblock[
(define pie 3.141592654)
]
On the other hand, if you just use the symbol @scheme[pie], it will be substituted by the defined value @scheme[3.141592654].

Hence, you use the quoting to escape evaluation.

@section{Functions}
Suppose we wish to evaluate several expressions with similar forms, such as these -
@schemeblock[
 (/ (- 100 30) (+ 100 30))
 (/ (- 10 5) (+ 10 5))
 (/ (- 31 7) (+ 31 7))
 (/ (- 355 113) (+ 355 113))
]

You notice first that only two numbers are involved in the expressions above, so the expressions all have the general form
@schemeblock[
(/ (- a b) (+ a b))
]
which computes @scheme[(a-b)/(a+b)].

You can define a function that will expand to the full expression when given  two numbers, as follows -
@schemeblock[
 (fn (a b) 
     (/ (- a b) (+ a b)))
]
(Notice the carefully matched parentheses.)

Since all expressions are ultimately values in muSE, the above function expression is itself a value, so we can give it a name using @scheme[define] as follows -
@schemeblock[
 (define f (fn (a b) (/ (- a b) (+ a b))))
]

After the above definition is evaluated, the symbol @scheme[f] now stands for the function @scheme[(fn (a b) (/ (- a b) (+ a b)))]. So we can simplify our original expressions to -
@schemeblock[
 (f 100 30)
 (f 10 5)
 (f 31 7)
 (f 355 113)
]
respectively.

    * Note that we use the terms @italic{function} and @italic{operator} interchangeably.

The expression immediately following the symbol @scheme[fn] is a list of @italic{unknowns} which will be @italic{bound} to particular values when using the function. In the above example, the list of unknowns is @scheme[(a b)]. Thus when evaluating the expression 
@schemeblock[
 (f 31 7)
]
the list of unknowns
@schemeblock[
 (a b)
]
is compared with the list of knowns  
@schemeblock[
 (31 7)
]
to determine the values that the unknowns must be @italic{bound} to. The effect of such a @italic{binding} is to replace the unknown symbols with their bound values throughout the body of the function, resulting in the following expression -
@schemeblock[
 (/ (- 31 7) (+ 31 7))
]
That's what we want.

@section{Applying operators to operands}

If the operands to be passed to an operator are available as the value of another symbol and not explicitly at the time of writing the expression, the operator can be @italic{applied} using the @scheme[apply] operator. This is possible because operators (aka functions) themselves are values that can be operands to other @italic{higher order operators}.

For example, lets assume we have the numbers from one to ten given as a list and the bound to the symbol @scheme[one-to-ten] -
@schemeblock[
 (define one-to-ten '(1 2 3 4 5 6 7 8 9 10))
]
If we want to add the numbers 1 to 10, we'll have to write -
@schemeblock[
 (+ 1 2 3 4 5 6 7 8 9 10)
]
, but since we only have the list of numbers as the value of a symbol, we need to @italic{apply} the operator @scheme[+] to the value of the symbol @scheme[one-to-ten] as follows -
@schemeblock[
 (apply + one-to-ten)
]
The above @scheme[apply] expression will evaluate correctly to 55.

The relationship between @scheme[apply] and @scheme[eval] can be summarized as -
@schemeblock[
(eval x) = (apply (eval (first x)) (map eval (rest x)))
]

You can imagine the @scheme[apply] operator to work like this -
@schemeblock[
 (apply + one-to-ten)
 (apply + '(1 2 3 4 5 6 7 8 9 10))
 (eval '(+ 1 2 3 4 5 6 7 8 9 10))
 (+ 1 2 3 4 5 6 7 8 9 10)
 55
]

@section{Truth and falsehood}

muSE uses the empty list @scheme[()] to represent falsehood. Any other value can be used to represent truth. This convention is used in evaluating comparison expressions such as -
@schemeblock[
 (> 3 2)
 (< 30 13)
 (>= 5.3 3.5)
 (and (>= 5.3 3.5) (< 314 355))
 (or (= 2 3) (= 3 2))
]

The symbol @scheme[T] is commonly used by such comparison operators to represent truth.

@section{Conditional evaluation}

@subsection{@scheme[if]}
The expression
@schemeblock[
 (if condition yes-value no-value)
]
evaluates to @scheme[yes-value] if the @scheme[condition] evaluates to something other than the empty list, otherwise it evaluates to @scheme[no-value].


For example -
@schemeblock[
 (if (< 2 3) 
     "muSE knows numbers" 
     "muSE doesn't know numbers")
]
will always evaluate to the string - @scheme["muSE knows numbers"]
because the expression @scheme[(< 2 3)] will always evaluate to
@scheme[T].

We can use the @scheme[if] conditional in our example function body to compute an absolute fraction - @scheme[|(a-b)/(a+b)|] as follows -
@schemeblock[
 (define f
         (fn (a b)
             (/ (if (< a b)
                    (- b a)
                    (- a b))
                (+ a b))))
]

If @scheme[a] and @scheme[b] are known to be positive numbers, then the expression -
@schemeblock[
 (if (< a b)
     (- b a)
     (- a b))
]
is guaranteed to be >= 0.

Notice how we're using the fact that @scheme[if] expressions evaluates to a single value and is not a control @italic{statement} like in other languages.

@subsection{@scheme[case]}
When you need to check for a few discrete values of a given expression, @scheme[case] proves effective. For example -
@schemeblock[
 (case N
     (1 "one")
     (2 "two")
     (3 "three"))
]
will evaluate to @scheme["one"], @scheme["two"], @scheme["three"] or @scheme[()] (the empty list) depending on whether @scheme[N] evaluates to @scheme[1], @scheme[2], @scheme[3], or some other value.

@section{Temporary names using @scheme[let]}

It is often the case that the value of a complex sub-expression is needed in several places in an expression. Either that, or we may wish to give the value of a sub-expression a name for the sake of clarity in reading the expression. For example, the sub-expression to compute the absolute difference of two numbers -
@schemeblock[
 (if (< a b) (- b a) (- a b))
]
in our example function can be named @scheme[difference]. We introduce such local definitions using the @scheme[let] notation as follows -
@schemeblock[
 (fn (a b)
     (let ((difference (if (< a b)
                           (- b a)
                           (- a b)))
           (sum (+ a b)))
          (/ difference sum)))
]

The @scheme[let] notation has the general form -
@schemeblock[
 (let ((_name1 _value1)
       (_name2 _value2)
       ....
       (_nameN _valueN))
   _expression)
]
where @scheme[_expression] makes use of the newly introduced @scheme[_name1], @scheme[_name2], etc.

@section{Recursive functions}

The term @deftech{recursion} is used to talk about ways to inductively specify a computation
on some data in terms of a computation on a subset of the data. (That's a simplified view, but it is
sufficient for introductory purposes.)

For example, say we want to add up all numbers from @scheme[_m] to @scheme[_n], we can describe the
calculation as follows -
@indent{To calculate the @emph{sum of numbers} from @scheme[_m] to @scheme[_n], you add @scheme[_m] to 
        the @emph{sum of numbers} from @scheme[_m + 1] to @scheme[_n], unless @scheme[_m] is greater than
        @scheme[_n], in which case the sum is taken to be @scheme[0].}
Note that @emph{sum of numbers} is specified in terms of itself. This is characteristic of @tech{recursive}
or @deftech{inductive} specifications. You can write such a summing function in muSE as follows -
@schemeblock[
(define (sum-of-numbers _m _n)
  (if (> _m _n)
      0
      (+ _m (sum-of-numbers (+ _m 1) _n))))
]

You can also define two functions in terms of each other. In such a case, the functions are said to be
@deftech{mutually recursive}. For example, the @scheme[even] and @scheme[odd] functions below are
defined mutually recursively.

@schemeblock[
(define (even n)) (code:comment "Declare even function")
(define (odd n)) (code:comment "Declare odd function")

(define (even n)
  (if (= n 0)
      'yes
      (odd (- n 1))))

(define (odd n)
  (if (= n 0)
      'no
      (even (- n 1))))
]

The above code says `` a number is even if its predecessor is odd and a number is odd if
its predecessor is even''. The definitions work for all @scheme[n >= 0].