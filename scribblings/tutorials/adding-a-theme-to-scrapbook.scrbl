#lang scribble/doc

@(require scribble/manual scribble/decode "../utils.ss")

@title[#:style 'quiet]{Adding a new theme to @onscreen{Scrapbook}}

Many styles tend to use stock art such as PNG graphics, short video clips
and sound effects. Therefore one of the easiest ways to create a ``new'' style is by 
changing the stock art of a style that resembles it. You'll usually need very little
editing of a style's @filepath{data.scm} file, if any at all, to create such a variant.

In this tutorial, we'll show you how to add a new theme to the  
@onscreen{Scrapbook} style that comes with muvee Reveal. You'll understand
how style graphics are usually structured, how to look for graphics usage
in @filepath{data.scm} files and how to edit your style's @filepath{strings.txt}
file to specify localized strings.


@bold{Note:} 
This tutorial assumes that you're familiar with the contents of 
@secref{Getting_Started} - i.e. you know the mechanics of creating a new style
based on an existing one and you've used the @muveeStyleBrowser . At the end of 
this tutorial, your Scrapbook style will end up modified. If you want to avoid that, 
you can copy it first and follow this tutorial on the copy instead.

@local-table-of-contents[]

@section{Preparation}

First you need to play around with the @onscreen{Scrapbook} style to
get a feel for what its productions look like. In particular, explore the
various options for @onscreen{Background} in the style settings panel. At the
moment, you have five background types - Life story, Grunge, Floral, 
Victorian and Abstract.

@bold{Note:} Quit muvee Reveal before proceeding with the following steps. 
Otherwise your changes to the style will not be picked up by Reveal.

@section{Poking around the style package}

@itemize{
  @item{Launch the @muveeStyleBrowser
        and locate the style named @onscreen{Scrapbook} in its listing.}
  @item{Right click on the @onscreen{Scrapbook} style and select @onscreen{Open style folder}.
        A folder named @tt{S00511_Journal2} will open. @tt{S00511_Journal2} is
        the id of the @onscreen{Scrapbook} style.}
  }

The style's folder contents will look like this -

@image["tutorials/image/scrapbookfiles.png"]

Each of the five folders corresponds to one of the background themes in @onscreen{Scrapbook}
and contains the theme's graphics. Each folder contains a set of numbered jpg files
(@filepath{001.jpg}, @filepath{002.jpg} and so on) and a @filepath{background.jpg} and a
@filepath{backpage.jpg}.  The numbered files are variations for different ``page''
patterns for your album pages. The @filepath{background.jpg} is for title and credits
and the @filepath{backpage.jpg} is how the reverse side of every ``page'' looks.

To create a new theme, you need to create one more such folder and populate it with
a similarly named set of files.

@section{The making of @tt{TheDarkSide}}

We're going to create a variation of the @onscreen{Abstract} theme called @onscreen{TheDarkSide}.
@itemize{
  @item{Copy the @filepath{Abstract} folder and name it @filepath{TheDarkSide}.}
  @item{Open each jpg file in the @filepath{TheDarkSide} folder in MS Paint,
        select @menuitem["Image" "Invert colors"] and save the result. This should 
        make the white portions black and black portions white. All colors are replaced 
        with their component-wise inverses.}
  }

For example,

@image["tutorials/image/abstract_background.jpg"] becomes 
@image["tutorials/image/thedarkside_background.jpg"]


@section{Adding @tt{TheDarkSide} to the @tt{data.scm}}

We need to make sure the @filepath["data.scm"] file will pickup the @filepath{TheDarkSide}
theme folder. 
@itemize{
  @item{Right-click on the @onscreen{Scrapbook} style in the muveeStyleBrowser and
select @onscreen{Edit data.scm}.}
       }

Near the start of the file, you'll find the following text -
@schemeblock[
(code:comment "-----------------------------------------------------------")
(code:comment "   Style parameters")

(style-parameters
  (#,(seclink "one-of-many_and_one-of-few" (scheme one-of-many))		THEME		Lifestory	(Lifestory  Grunge  Floral  Damask  Abstract))
  (continuous-slider	AVERAGE_SPEED	0.5		0.0  1.0)
  (one-of-few		FLIP_STYLE	Curl		(Curl  Roll))
  (continuous-slider	FLIP_VARIATION	0.25		0.0  1.0))
             ]

The @scheme[one-of-many] parameter @scheme[THEME] seems to correspond to the drop-down box 
for the @onscreen{Background} parameter. Indeed, if you look into the style's @filepath{strings.txt}
file, you'll find the English name of the @scheme[THEME] parameter to be @onscreen{Background}.

@itemize{
  @item{Change the @scheme[THEME] line to add a new symbol @scheme[TheDarkSide].
@schemeblock[
  (one-of-many		THEME		Lifestory	(Lifestory  Grunge  Floral  Damask  Abstract TheDarkSide))
             ]
}}

We now need to do for @scheme[TheDarkSide] everything that is done to, say, @scheme[Abstract].
@schemeblock[
....
(define TEXT_COLOR
  (case THEME
    ('Abstract 0xFF446D84)
    (code:comment "----- Insert the following line. -----")
    ('TheDarkSide 0xFFBB927B) (code:comment "Invert 'Abstract's color.")
    (code:comment "-----------------------------------")
    ('Damask 0xFFAB752D)
    ('Floral 0xFFD8D8D4)
    ('Grunge 0xFF7A6015)
    ('Lifestory 0xFF854B09)))

(define TEXT_FONT
  (case THEME
    ('Abstract "-21,0,0,0,400,0,0,0,0,3,2,1,34,Microsoft Sans Serif")
    (code:comment "----- Insert the following line. -----")
    ('TheDarkSide "-21,0,0,0,400,0,0,0,0,3,2,1,34,Microsoft Sans Serif") (code:comment "Copy font string from 'Abstract.")
    (code:comment "-----------------------------------")    
    ('Damask "-23,0,0,0,400,0,0,0,0,3,2,1,34,Palatino Linotype")
    ('Floral "-24,0,0,0,400,1,0,0,0,3,2,1,34,Times New Roman")
    ('Grunge "-20,0,0,0,700,0,0,0,0,3,2,1,34,Impact")
    ('Lifestory "-21,0,0,0,700,1,0,0,0,3,2,1,34,Georgia")))

(define TEXT_LAYOUT_Y
  (case THEME  
    ('Abstract (cons 0.30 0.90))
    (code:comment "----- Add the following line. -----")
    ('TheDarkSide (cons 0.30 0.90)) (code:comment "Copy from 'Abstract.")
    (code:comment "-----------------------------------")    
    (_ (cons 0.10 0.90))))
....
]

@section{Naming things right}

We finally need to edit Scrapbook's @filepath{strings.txt} to specify the name for 
the @scheme[TheDarkSide] theme. Right click on @onscreen{Scrapbook} in the muveeStyleBrowser
and select @onscreen{Edit strings.txt}. That should open up the strings file in your
text editor of choice.

Add the following line, say somewhere near the strings specification of the @scheme[Abstract]
theme. It is polite to acknowledge where you copied stuff from :) So we make it clear that
@scheme[TheDarkSide] theme is based on the @scheme[Abstract] theme.
@schemeblock[
TheDarkSide     en-US   Abstract - the dark side
]

@indent{@bold{Warning:} Do not copy the text above as is. Type it in. There has to be exactly
one @tt{tab} character separating @tt{TheDarkSide}, @tt{en-US} and @tt{Abstract - the dark side}.}

@section{Enjoying the fruits of your labour}

@itemize{
  @item{Launch muvee Reveal}
  @item{Add some pictures}
  @item{Select the @onscreen{Scrapbook} style. Change the 
        @onscreen{Background} parameter in the style settings panel
        to @onscreen{Abstract - the dark side}.}
  @item{Click the play button.}
  }

You'll see that your new abstract images are being used in the production.

@section{Being picky}

As you watch the muvee, you might notice that the back side of the pictures are
all totally black. This is because the white backpage.jpg got turned into a totally
black image when we inverted it. 

For an easy fix to this, just copy the @filepath{background.jpg} to @filepath{backpage.jpg}.

@section{Some details}

@subsubsub*section{Getting the folder name from the theme symbol}

If you followed the above instructions carefully, you might have been surprised by
the fact that nowhere did we say @emph{the theme called @scheme[TheDarkSide] corresponds
to the folder @filepath{TheDarkSide/}.} Well, in fact there *is* such a place and it is this 
piece of code in the @filepath{data.scm} file -
@schemeblock[
....
(define theme-path
  (fn (file)
    (format THEME "/" file)))
....
             ]

What the @scheme[theme-path] function does is to derive the name of a file that belongs to a theme
by using the string form of the symbol for the theme as the name of the folder
containing the theme. That's why giving @scheme[TheDarkSide] as the new theme's symbol
was sufficient for it to be linked to the folder @filepath{TheDarkSide/}.

@subsubsub*section{What are @scheme[TEXT_COLOR], @scheme[TEXT_FONT] and @scheme[TEXT_LAYOUT_Y]?}

In general, to understand what a defined symbol
does, look at the places where it is used. For the @onscreen{Scrapbook} style, these
@scheme[TEXT_....] symbols are used near the end of the file, in the title
and credits specification.

@schemeblock[
(#,(seclink "Title_and_Credits" (scheme title-section))
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color #,(bold (scheme TEXT_COLOR)))
    (font #,(bold (scheme TEXT_FONT)))
    (layout (0.10 (first #,(bold (scheme TEXT_LAYOUT_Y))))
            (0.90 (rest #,(bold (scheme TEXT_LAYOUT_Y)))))))

(#,(seclink "Title_and_Credits" (scheme credits-section))
  (background
    (image BACKGROUND_IMAGE))
  (foreground
    (fx FOREGROUND_FX))
  (text
    (align 'center 'center)
    (color #,(bold (scheme TEXT_COLOR)))
    (font #,(bold (scheme TEXT_FONT)))
    (layout (0.10 (first #,(bold (scheme TEXT_LAYOUT_Y))))
            (0.90 (rest #,(bold (scheme TEXT_LAYOUT_Y)))))))
]