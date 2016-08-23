#lang scribble/doc

@(require scribble/manual "utils.ss")

@title[#:style 'toc]{Tutorials}

Each tutorial walks you through a specific aspect of making a muvee style.
They usually develop one style in various stages that are individually
accessible via the tutorial's style-list URL. You can paste this style-list
URL into the address field of the muveeStyleBrowser to get a list of styles
for you to try out as you work through the tutorial.

@subsubsub*section{On muSE and Scheme}

The behaviour of muvee styles are specified in a scripting language we
call ``muSE'' - which is short for ``muvee Symbolic Expressions''.
muSE is dialect and subset of a family of programming languages called Scheme.
Each style has a @filepath{data.scm} file containing muSE script that
specifies the behaviour of the style. 

@margin-note{More about @secref{muSE}.}

As of this writing, the muSE interpreter embedded 
into muvee Reveal is not very forgiving of errors in @filepath{data.scm} 
files. Under most circumstances, it will show you a (hopefully) helpful 
dialog box describing the situation and the context, but in others it is 
not so aware. So be on your guard and save your work frequently. 

You can prevent many muSE coding errors if you use the 
@link["http://www.drscheme.org"]{DrScheme} IDE to author your muSE code. 
DrScheme is aware of Scheme syntax and will highlight parentheses
groups to guide you automatically. Of course, you can use any
text editor, including Notepad, to edit @filepath{data.scm} files.

@subsubsub*section{Suggestions on working through the tutorials}

There are two ways to work through these tutorials -
@itemize{
         @item{Read through from start to finish, follow the instructions,
               writing all the code you need to by yourself. We recommend
               you do this since it'll give you a good feel of the whole
               style development process.}
         @item{... or Launch the muveeStyleBrowser, copy-paste the tutorial URL
               (shown at the start of each tutorial) into the address bar and 
               press the enter key. You'll
               see a list of styles that trace through the various stages of 
               this tutorial. You can install all of them and try out each
               one as you read through the corresponding stage. This is obviously
               less work than the first approach, so you can do it this way if 
               you just want a taste of it all.}
         }

@subsubsub*section{The tutorials}
@local-table-of-contents[]
@include-section["tutorials/adding-a-theme-to-scrapbook.scrbl"]
@include-section["tutorials/basic-editing.scrbl"]
@include-section["tutorials/putting-a-bounce-into-reflections.scrbl"]
@;@include-section["tutorials/effect-composition.scrbl"]

