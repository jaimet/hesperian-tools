#!/usr/bin/perl -w
# Wrapper for various ImageMagick convert functions. 
# "perldoc image_convert.pl" for the details.

use strict;
use Getopt::Long;

use File::Basename;
use File::Path qw(make_path);
use File::Find;

$ENV{'PATH'} .= ':/usr/local/bin/';

my $convert = "convert";
 
my ($resizeSize, $degrayAlpha, $wikidir);

GetOptions("resizeSize:s", \$resizeSize,
  "degrayAlpha:s", \$degrayAlpha,
  "wikidir", \$wikidir);

$resizeSize = $resizeSize || '1000x1000>';
$degrayAlpha = $degrayAlpha || '.09';

my ($Command, $Source, $Dest) = @ARGV;

my @transparent = split(/ /, '-matte -channel Alpha -fx a*(1-(r+b+g)/3.0) -channel red -fx 0 -channel green -fx 0 -channel blue -fx 0');

my @resize =  (split(/ /, '-density 72 -resize'), $resizeSize);

my @degray = split(/ /, "-matte -channel alpha -fx (a-1)/(1-$degrayAlpha)+1 -channel red -fx 0 -channel green -fx 0 -channel blue -fx 0");

my %Converts = (
  'transparent' => \@transparent,
  'resize' => \@resize,
  'degray' => \@degray,
);


my @cmd_base = ($convert);

foreach my $cmd (split('\+', $Command)) {
  die "Unknown command $Command" unless exists($Converts{$cmd});
  push (@cmd_base, @{$Converts{$cmd}});
}

sub do_command {
  my ($i, $o) = @_;
  my @cmd = (@cmd_base, $i, $o);
  print join(' ',@cmd), "\n";

  my $basedir = dirname($o);
  make_path($basedir);

  my $rc = system(@cmd);
  if ($rc & 127) { die "convert terminated" }
  return $rc;
}

sub do_one_image {
  return unless -f $_;
  my $bn = basename($_);
  return if $bn =~ /^\./;

  my $destpath = $Dest . substr $_, length($Source);
  do_command($_, $destpath);
};

if (-d $Source) {  
  $Source =~ s|/*$||; # remove trailing slashes

  my @ImageDirs = $wikidir ?  map { "$Source/$_"} qw(0 1 2 3 4 5 6 7 8 9 a b c d e f): ($Source);

  find({ wanted => \&do_one_image, no_chdir => 1 }, @ImageDirs);
} else {
  do_command($Source,$Dest);
}

0;

=head1 NAME

image_convert.pl - wrapper for various ImageMagick convert manipulations.

=head1 SYNOPSIS

./image_convert.pl [--resizeSize=convertSize | --degrayAlpha=alpha] command[+command]* source_file target_file

./image_convert.pl [--wikidir] [--resizeSize=convertSize | --degrayAlpha=alpha] command[+command]* source_directory target_directory

=head1 DESCRIPTION 

We'll wrap up various ImageMagick convert commands by name. Multiple commands can be requested by concatinating the command names with '+'.

In the first synopsis form, image_convert.pl transforms F<source_file> to F<target_file>. 

In the second synopsis form, image_convert.pl recursively transforms the files under F<source_directory> into F<target_directory>, mirroring the hierarchy structure.
Pass the --wikidir option to limit subdirectories to those designated for mediawiki images ('0'...'f').

=head2 commands

=over

=item transparent

Make the image transparent, based on the assumption that it's a black image composited over a white background.

=item resize

Reduce the image to a standard (maximum) size, preserving aspect ratio. Override the size with the --resizeSize=convertSize option.

=item degray

Make the image transparent, based on the assumption that it's a black image compositied over a full black with alpha background.
Override the presumed background alpha with --degrayAlpha=alpha

=back

=head1 SEE ALSO

ImageMagick L<http://www.imagemagick.org>

=head1 AUTHOR

Matthew Litwin <mlitwin@sonic.net>


=cut

