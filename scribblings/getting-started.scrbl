#lang scribble/doc
@(require scribble/manual scribble/struct "utils.ss")

@title{Getting Started}

Here you can learn about the operations required to create a new muvee style
based on an existing one. Just follow through the simple steps below and you'll 
have your own muvee style to play with at the end. 

@local-table-of-contents[]

@section{Setup}

@itemize{

@item{If you haven't done so already, install @link["http://www.muvee.com/en/products/reveal/"]{muvee Reveal}. 
If you already have a registered version of the product, great. If you don't,
the trial version is sufficient for authoring styles. Do make sure you're running
the latest version.

@emph{Note:} Make sure your computer satisfies our system recommendations on the download 
site. You're in great shape if you have a PC with a 2GHz+ dual core processor running XP or 
Vista, at least 1GB of RAM and a nice OpenGL 1.4+ compatible PCI-Express graphics card 
with at least 128MB of video memory. }
     
@item{Install the  @link["http://code.google.com/p/muvee-style-authoring/downloads/list"]{muveeStyleBrowser}.
It is a tool for browsing and installing the styles published on
the @link["http://muvee-style-authoring.googlecode.com/"]{@tt{muvee-style-authoring}}
site including examples and tutorials. It is a useful tool to manage your own
styles as you create them based on those published online. Much of the
documentation on this site will (eventually) refer to the muveeStyleBrower.
}

@item{We recommend you install @link["http://www.drscheme.org"]{DrScheme} for use as
your editor for style @filepath{data.scm} files. If you're only going to be
editing a style's graphics, you won't need DrScheme.}
}
           
@section{Copy the blank template style}
Launch the muveeStyleBrowser and select @menuitem["Bookmarks" "Examples"]
for it to load the list of examples. 
If you're not your computer's administrator, you'll need to launch the muveeStyleBrowser 
by right clicking and selecting ``Run as administrator''.
Otherwise, Windows will not let you edit files of muvee-made styles. 

You should see - 

@image["image/msb_examples.png"]

Right click on the ``Blank Template'' style to get the 
following contextual menu -

@image["image/msb_derivenewstyle.png"]

Select @onscreen{Derive new style ...} to make a copy 
of the blank template style to your machine. Change the id to @tt{S10000_MyFirstStyle}
when prompted for a new style id. (Don't worry about what
the 10000 means for the moment.) You should now see -

@image["image/msb_myfirststyle.png"]
                                 
@section{Change the name and description of your style}
Right click on your new style to get the following contextual menu -

@image["image/msb_editstringsmenu.png"]

Select the @onscreen{Edit strings.txt} action to open
your style's @filepath{strings.txt} file in your default
text editor (probably Notepad). You'll see two lines specifying the short
name of your style (@scheme[STYLENAME]) and a longer description
of your style (@scheme[STYLEDESC]) as shown below - 

@image["image/msb_openstrings.png"]

Change your style's name and description to whatever you like, for
example, you can change it to the strings shown below - 

@image["image/msb_editstrings.png"]

Save the file, close your editor and return to the muveeStyleBrowser window.
You'll notice that the old names continue to be displayed. To refresh,
right click on your style and select @onscreen{Refresh} and you should see
your new name and description appear.

@section{Add a visual effect}
To visually distinguish your style from 
the blank template, we're going to apply a @secref["Sepia"] tone to it. 
@itemize{
         @item{Right click on your style and select @onscreen{Edit data.scm}.}
         @item{Add the following line at the end of your @filepath{data.scm} file.
                   @schemeblock[
                                (define muvee-global-effect (effect "Sepia" (A)))
                                ]
                   }
         @item{Save and close your @filepath{data.scm} file editor.}
         }

@section{Style icon and preview (optional)}
You can change your style's icon by editing the @filepath{icon.png}
file in your style's folder. To open your style's folder, right
click on your style and select @onscreen{Open style folder}.

The @filepath{preview.wmv} file in your style's folder is expected 
to be a short video preview of what your style looks like. 
The muvee Reveal interface plays this video when you select a style. 
You can generate the preview video after you complete your style, so 
you can leave the preview file alone for now.

@section{Launch muvee Reveal}
Once muvee Reveal is launched, you should see your style named ``My first style''
in the style list. When you launch the muveeStyleBrowser or click on the @onscreen{My styles}
button, you'll see a list of styles that's identical to the list that is shown by
muvee Reveal.

@bold{Congratulations!!} Although your style is pretty bare bones, it already does a
lot. You can use pictures and video with it, it will summarize video to the
duration you set, and it will respond to practically every setting you throw at it
via the muvee Reveal interface.

@section{Now what?}

@itemize{
         @item{If you want to work directly with style folders bypassing the muveeStyleBrowser, you'll need the info in @secref["Style_Package_Structure"].}
         @item{If you're not very familiar with video editing systems, you should acquaint yourself with @secref["Anatomy_of_a_muvee"] first. }              
         @item{@secref["Tutorials"] walk you through various aspects of style authoring.}
         @item{If you want to play with effects, you'll find thumbing through the @secref["List_of_primitive_effects_and_transitions"] useful, maybe even inspiring.}
         }
