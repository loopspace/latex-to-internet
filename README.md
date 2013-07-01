# Licence #

Copyright 2013 Andrew Stacey.

This work may be distributed and/or modified under the conditions of the LaTeX Project Public License, either version 1.3 of this license or (at your option) any later version.

The latest version of this license is in [LPPL](http://www.latex-project.org/lppl.txt) and version 1.3 or later is part of all distributions of LaTeX version 2005/12/01 or later.

This work has the LPPL maintenance status "maintained".

The Current Maintainer of this work is Andrew Stacey.

This work consists of all of the files in [this repository located on GitHub](https://github.com/loopspace/latex-to-internet).

# Introduction #

The `internet` class and suite of modules is designed to make it possible to write a wide range of documents using LaTeX as the input format. It is **not** intended as a conversion tool but the intention is for an author to use it from the outset. Using it, an author can write a blog post, a wiki page, an ePub document, or more, using their knowledge of and skills with LaTeX. It is also possible to use the same source to produce a variety of different outputs (including letting TeX do its usual thing to produce a PDF or DVI).

# Limitations #

When writing a document intended for, say, a blog post then there are certain limitations that are not faced when TeX is creating a PDF or DVI in its normal fashion. In its normal mode, TeX is in control of the entire process and is therefore able to make decisions based on precise information about the final form. This is not possible when the final form that TeX produces is to be further interpreted by, say, a web browser. Therefore anything that involves TeX knowing the final form cannot be replicated. Unfortunately, it is not always obvious what these things will be.

This means that there is no guarantee that a document originally written as an ordinary LaTeX document will produce something usable. Therefore this works best for documents written afresh with these limitations known and accepted beforehand.

# Installation #

Various files need to be in places where TeX can find them. Every file from this repository of the form `internet<type>.<format>.code.tex` should be linked in to your local `texmf` tree. The same goes for the `hyperref` driver files of the form `h<type>.def` and the main `internet.cls` file.

There are two virtual font files, `mathfont.vpl` and `textfont.vpl`. The corresponding `.tfm` and `.vf` files need to be generated with the `vptovf` file:


```
vptovf textfont.vpl
vptovf mathfont.vpl
```

The resulting `.tfm` and `.vf` files need to be put somewhere that TeX can find them.

All of the `<format>_test.tex` are test files and not needed for compiling documents.

The class and its modules are written in LaTeX3. A recent installation is recommended. For processing hyperlinks, a version of `hyperref` at least as recent as version 6.83f (dated 2012-09-25) is required.

There are also some additional programs and tools needed or recommended (depending on the format).

The `pdftotext` program is essential as TeX produces a PDF and that needs converting to text. It doesn't always get the extraction correct and one area where it is not reliable is with initial indentation. For formats where this is significant, therefore, the initial indent is replaced by placeholder letters which should then be replaced by genuine spaces.

The `latex2txt.sh` will compile the document, run `pdftotext` on the resulting PDF, and fix the indentations.

At present, the output formats that convert mathematics to MathML do not do so natively (this is planned). Rather, it converts it to a format suitable for the `itex2MML` program which will then produce the MathML. Thus if either XHTML or ePub3 is the final format the `itex2MML` program is needed. The original of this is available from [Jacques Distler](http://golem.ph.utexas.edu/~distler/blog/itex2MML.html). A version with bindings for more languages is available as a [BZR repository](http://www.math.ntnu.no/~stacey/code/itexToMML/). This is used in the `create_epub.pl` perl script in this repository.

# Usage #

This is a documentclass so is used as `\documentclass[<options>]{internet}`. The `<options>` specify a variety of things. The primary ones being the desired *type* of output and the *format*. The *type* is related to where the document should end up. Most likely, it will be the language of the final format such as `markdown`. The *format* selects between ordinary LaTeX processing (possibly with some special processing depending on the *type*) and producing the desired text document (via a PDF).

The currently available types are:

* Markdown, `markdown`

* Markdown Extra, `markdownextra`
* Maruku, `maruku`

* Instiki, `instiki`

* Wordpress, `wordpress`

* XHTML, `xhtml`

* ePub3, `epub`

There are also options as to how the mathematics is translated. At present, these are:

* Basic, `basicmaths`

* iTeX, `itex`

# Known Issues #

1. One of the most persistent issues is how backticks get processed. I have yet to figure this one out, and if backticks are significant then sometimes the resulting file needs running through an appropriate script.
