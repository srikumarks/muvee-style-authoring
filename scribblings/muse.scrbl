#lang scribble/doc
@(require scribble/manual)

@title{muSE}

The behaviour of muvee styles in Reveal is specified in a scripting language we 
call ``@deftech{muSE}'' - which is short for ``muvee Symbolic Expressions''. 
muSE is a dialect and subset of a family of programming languages collectively
called ``Scheme''. Each muvee style has a @filepath{data.scm} file containing
muSE code that specifies its behaviour.

@itemize{
         @item{See @link["http://muvee-symbolic-expressions.googlecode.com"]{muvee-symbolic-expressions}
               on googlecode for details on the open sourced core language.}
         @item{See @secref{A_Gentle_Introduction_to_muSE} if you aren't familiar
               with muSE or Scheme, or for a quick recap if you haven't used
               them in a while.}
         @item{Post questions about core muSE to @link["http://groups.google.com/group/muvee-symbolic-expressions"]{muSE's own forum}}
         @item{Post questions about use of muSE for style authoring to the
                    @link["http://groups.google.com/group/muvee-style-authoring"]{style authoring forum}.}
         }
               