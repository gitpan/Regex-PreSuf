require 5;

use ExtUtils::MakeMaker;

open(VERSION, "VERSION") and
    chomp($version = <VERSION>) and
    close(VERSION);
die "Version undefined: $!\n" unless defined $version;
die "Version $version illegal\n" unless $version > 0;

use Cwd;

my $cwd = getcwd();

die "This directory ($cwd)\ndoes not look like version $version.\n"
    unless $cwd =~ /\Q$version\E$/;

if ( -M "PreSuf.pm" > -M "VERSION" or -M "PreSuf.pm" > -M "Makefile.PL" )  {
    print "Updating PreSuf.pm to version $version\n";
    local($^I, @ARGV) = ('.bak', 'PreSuf.pm');
    while (<>) {
        s/^(Version|\$VERSION\s*=)\s*(?:\d.+)([.;])$/$1 $version$2/;
        print;
        close ARGV if eof;
    }
}

WriteMakefile(
    'NAME'      => 'Regex::PreSuf',
    'VERSION'   => $version,
    'dist'      => { 'COMPRESS' => 'gzip' }
);
