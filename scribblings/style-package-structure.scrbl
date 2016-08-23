#lang scribble/doc
@(require scribble/manual)
@(require scribble/struct)

@title{Style Package Structure}

@link["http://www.muvee.com/en/products/reveal/"]{muvee Reveal} comes bundled with several @emph{styles} that you can use to personalize your muvees. More styles are also available from our @link["http://www.muvee.com/en/stylelabs/reveal"]{style labs} page.

This document describes the package structure 
of all styles, including those shipped via our Style Labs page,
but the @link["http://muvee-style-authoring.googlecode.com/downloads/list"]{muveeStyleBrowser} 
provides a more convenient way to access, download, install, uninstall and edit the styles
published on @tt{muvee-style-authoring}. You don't need to get
into these details if you do not want to customize any of muvee's own commercial
styles, including those bundled with muvee Reveal.

You can use this information to -
@itemize{
  @item{Change the name of a style,}
  @item{Localize a style's name and description to your taste,}
  @item{Change a style's icon,}
  @item{Change any stock graphics used by the style,}
  @item{Create variations of a style.}
  }

@section{Location}

Styles are usually installed in the directory - @filepath["C:\\Program Files\\Common Files\\muvee Technologies\\071203\\"]. The drive letter might differ depending on your installation location. A standard muvee Reveal installation will have the following style packages in the above installation directory -
@schemeblock[
  S00509_MusicVideo3
  S00510_SportHex
  S00511_Journal2
  S00512_Strips
  S00513_Reflections2
  S00514_UltraPlain
  S00516_Plain
  S00517_Showreel
  S00518_Cube
]

The name of a style package, as exemplified above, has the structure - 

@filepath{S<5-digit-number>_Identifier} 

A style package is a directory with specific structure and contents.

@section{Package contents}

Let us look at the ``Ultra Plain'' style's package structure, which is the simplest of the bundled styles.
@itemize{
         @item{@tt{S00514_UltraPlain/}
               @itemize{
                        @item{@tt{icon.png}}
                        @item{@tt{preview.wmv}}
                        @item{@tt{strings.txt}}
                        @item{@tt{data.scm}}}}}

Every style must have at least these four files in order to be visible within the muvee Reveal interface and these files must have exactly the names shown above.

@subsection{icon.png}
This is the style's icon which will be displayed in the styles pane of muvee Reveal. The format is as follows -
@itemize{
         @item{Dimensions = 50w x 50h}
         @item{Format = png}
         @item{Bit depth = 32}
         }

@subsection{preview.wmv}
This is a video file that shows what the style looks like. It is played in the muvee Reveal interface when you select the style. You can generate a preview video for your own styles using muvee Reveal itself. The format of the preview file is as follows -
@itemize{
         @item{Dimensions = 240w x 180h}
         @item{Duration = 10 seconds}
         @item{Format = WMV9}
         @item{Bit rate approximately 140kbps}
         @item{No sound track}
         }

@subsection{strings.txt}
A UTF-8 encoded plain text file that contains the localized name and description strings. It also contains the localized names of all the parameters exposed by the style in its @italic{Style Settings} panel. You can view the contents of this file using the Notepad program that comes with Windows XP or Vista.

@subsection{data.scm}
A plain text file (utf-8) containing a script that specifies the various aspects of a style such as exposed parameters, music response, effects and transitions, title/credits and such. For more on the contents of a @filepath{data.scm} file, see @secref{Specifying_Style_Behaviour}.

@section{Resources}

The ``Ultra Plain'' style is .. well .. ultra plain, but other styles such as ``Hexplode'' (@tt{S00510_SportHex}) and ``Scrapbook'' (@tt{S00511_Journal2}) make use of images and video clips to create their unique looks. The folders of these styles therefore also contain additional image and video files.

There is no general naming convention used for style resources and you might find that some of them are obvious (ex: @tt{background.wmv}) whereas others aren't (ex: @tt{004.png}). The role played by a particular resource file is specific to the style.

If you change a style's graphics resources, while retaining the original file names, you can dramatically change the look of a style. You can also mix and match resources from different styles to create hybrid styles. If you're a Photoshop-er, you might have fun playing around with these files.

@section{Creating a variant style}

Now that you know about the structure of a style, it is time to create your own variant of an existing style.
@itemize{
  @item{Select the package folder of the style that you want to create a variant of.}
       @item{Copy the style package in its entirety and give it a unique name along the lines of @filepath{S<5-digit-number>_Identifier}. You can copy, say, @filepath{S00517_Showreel} and name the folder as @filepath{S00517_MyShowreel}.}
       @item{Change the name of your style.
             @itemize{
                       @item{Open the @filepath{strings.txt} file in your copy,}
                       @item{Locate the line that says @schemeblock[STYLENAME    en-US    Uncle Oscar] (for English text)}
                       @item{Edit the ``Uncle Oscar'' part to whatever you want to call your variant, say ``Film strips''.}
                       @item{(Re)launch muvee Reveal. You'll find a new style in the panel called ``Film Strips''.}
                       }}
}

You can then customize the variant style's icon, preview and graphics resources to achieve the different look that you desire. 

If you think you've created something interesting, do write about it to the @link["http://groups.google.com/group/muvee-style-authoring"]{muvee-style-authoring} group.

@section{More about @tt{strings.txt}}

Open a @filepath{strings.txt} file using Notepad and you'll see that it consists of a 3-column table with a single @tt{<tab>} character separating the columns. The first column gives the @emph{String ID}. 

The ID @tt{STYLENAME} stands for the name of a style as displayed in the muvee Reveal interface. The ID @tt{STYLEDESC} stands for the descriptive string shown along with the name of the style in the muvee Reveal interface. These two IDs are present in the strings.txt file of any style.

The second column selects a language. For example, "en-US" stands for "English US". In conjunction with the string ID of the first column, it uniquely selects a unicode string for use in the muvee Reveal interface. For example, @tt{STYLENAME    en-US} selects the string for the style's name in "English US", the entry @tt{STYLEDESC    ru-RU} selects the string for the style's description in "Russian", and so on.

The third column contains the actual string encoded in UTF-8.
