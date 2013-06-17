#! /usr/bin/perl -w

use ItexToMML;
use MathML::Entities;

my $file = $ARGV[0];
my $base;
my $pdf;
my $epubcheck = $ENV{HOME} . '/local/share/epubcheck-3.0/epubcheck-3.0.jar';
my $debug = 1;

die "No file specified.\n" unless ($file);

$file =~ s/\.$//;

if ($file =~ /\.tex$/) {
    ($base = $file) =~ s/\.tex$//;
} else {
    $base = $file;
    $file .= '.tex';
}

if (! -e $file ) {
    die "$file not found\n";
}

$pdf = $base . ".pdf";
my $epub = $ENV{PWD} . '/' . $base . '.epub';
my $cdir = $ENV{PWD};
unlink($epub);

system("pdflatex", $file);
system("pdflatex", $file);
system("pdftotext", "-enc","ASCII7", "-nopgbrk", "-layout", $pdf);


my $itex = new ItexToMML;
my $src;

my $txtfile = $base . ".txt";
open(TEXT, $txtfile)
    or die "Couldn't open $txtfile for reading\n";

while (<TEXT>) {
    $src .= $_;
}

close TEXT;

my $res = $itex->html_filter($src);
my $utf8 = name2numbered($res);
my @files;

# Now assemble the ePub
my $tmpdir = "/tmp/epub-" . $$;

mkdir($tmpdir,0777)
    || die "Couldn't create $tmpdir\n";
mkdir("$tmpdir/META-INF",0777)
    || die "Couldn't create $tmpdir/META-INF\n";
mkdir("$tmpdir/OEBPS",0777)
    || die "Couldn't create $tmpdir/OEBPS\n";

my $ftxt;

while ($utf8 =~ s/<!-- start of ([a-zA-Z._0-9-]+) -->(.*)<!-- end of \1 -->//s) {
    push @files, $1;
    open(SEC,">$tmpdir/OEBPS/$1")
	|| die "Couldn't open $1 for writing.\n";
    ($ftxt = $2) =~ s/^\s*//s;
    $ftxt =~ s/\s*$//s;
    print SEC $ftxt;
    close SEC;
}

if ($utf8 =~ s/<!-- start of file list -->(.*)<!-- end of file list -->//s) {
    my $flist;
    ($flist = $1) =~ s/<!--\s*(.*?)\s*-->/$1/g;
    my @f = split("\n", $flist);
    for my $file (@f) {
	if (!-e $tmpdir . "/OEBPS/" . $file) {
	    system ('cp', $file, $tmpdir . "/OEBPS/");
	    push @files, $file;
	}
    }
}

my $xhtml = $tmpdir . "/OEBPS/" . $base . ".xhtml";

if ($utf8 !~ /^\s*$/s) {

    open (SEC, ">$xhtml")
	|| die "Couldn't open $xhtml for writing.\n";

    print SEC $utf8;
    
    close SEC;

}
# mimetype file
open(MIME, ">$tmpdir/mimetype")
    || die "Couldn't open mimetype for writing.\n";

print MIME "application/epub+zip";

close MIME;

open(CONT, ">$tmpdir/META-INF/container.xml")
    || die "Couldn't open container.xml for writing.\n";

print CONT q{<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
     media-type="application/oebps-package+xml" />
  </rootfiles>
</container>};

close CONT;

chdir($tmpdir);
system('zip', '-X0', $epub, 'mimetype');
system('zip', '-rDX9', $epub, '.', '-x', 'mimetype');

chdir($cdir);

if (!$debug) {
unlink($xhtml);
for my $f (@files) {
    unlink ($tmpdir . '/OEBPS/' . $f);
}
unlink("$tmpdir/mimetype");
unlink("$tmpdir/META-INF/container.xml");

rmdir("$tmpdir/META-INF");
rmdir("$tmpdir/OEBPS");
rmdir("$tmpdir");
}
system('java', '-jar', $epubcheck, $epub);

exit 0;
