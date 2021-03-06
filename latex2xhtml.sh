#! /bin/bash

if [ -e $1 ]; then
    texfile=$1
else
    if [ -e $1.tex ]; then
	texfile=$1.tex
    else
	echo "Error: file $1 not found"
	exit 1
    fi
fi

ext="${texfile: -3}"
base="${texfile%.$ext}"

if [ $ext != "tex" ]; then
    echo "Error: $texfile is not a tex file"
    exit 1
fi

pdflatex $texfile

if [ $? -ne 0 ]; then
    echo "Error: pdflatex failed to run cleanly"
    exit $?
fi

pdftotext -enc ASCII7 -nopgbrk $base.pdf

if [ $? -ne 0 ]; then
    echo "Error: pdftotext failed to run cleanly"
    exit $?
fi

itex2MML < $base.txt > $base.xhtml

if [ $? -ne 0 ]; then
    echo "Error: itex2MML failed"
    exit $?
fi

echo "Conversion successful!  Your text is available as $base.xhtml"
