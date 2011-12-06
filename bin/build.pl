#!/usr/bin/perl

use Modern::Perl;
use Garden;
use JSON;
use DateTime;

our $API; ## The API release number. Always the second field in VERSION.

sub slurp {
  my $filename = shift;
  my $text = do { local( @ARGV, $/ ) = $filename ; <> } ;
  return $text;
}

sub output_file {
  my ($outfile, $content) = @_;
  open(my $file, '>', $outfile);
  print $file $content;
  close $file;
}

sub output_html {
  my ($page, $content) = @_;
  my $outfile = "./spec/$API/$page.html";
  output_file($outfile, $content);
}

my $pages = decode_json(slurp('./src/pages.json'));
my $version = slurp('./VERSION'); ## The release name.
my $garden = Garden->new(paths=>['./src']);
my @verspec = split(/\s+/, $version);
$API = "v".$verspec[1]; ## v1, v2, etc.
my $ver = 0;            ## The specific version (DRAFT1, RC3, REV2, etc.)
if (@verspec > 2) {
  $ver = $verspec[2];
}
my $releases;
my $relfile = './spec/releases.json';
if (-f $relfile) {
  $releases = decode_json(slurp($relfile));
}
else {
  $releases = {};
}

$garden->addGlobal('VERSION', $version); 

my $inf = 0; ## Build the info.json file?
my $toc = 0; ## Build table of contents?
my $sp  = 0; ## Build single page?
my $all = 0; ## Build ALL pages?
my %build;   ## Specific pages to build.
if (@ARGV) { 
  for my $arg (@ARGV) {
    given ($arg) {
      when (/^\-i/) { $inf = 1; }
      when (/^\-t/) { $toc = 1; }
      when (/^\-s/) { $sp  = 1; }
      when (/^\-a/) { $all = 1; }
      default {
        $build{$_} = 1;
      }
    }
  }
}

if ($inf || $all) {
  say "Building version information file.";
  my $date = DateTime->now();
  my $info = {
    "date"    => "$date",
    "rev"     => $ver,
  };
  $releases->{$API} = $info;
  my $json = JSON->new->utf8->pretty->encode($releases);
  output_file($relfile, $json);
}

if ($toc || $all) {
  say "Building table of contents.";
  my $tocpage = $garden->get('index');
  my $tochtml = $tocpage->render(sections=>$pages);
  output_html('index', $tochtml);
}

for my $section (@{$pages}) {
  for my $page (@{$section->{pages}}) {
    if (exists $page->{file}) {
      if ($all || exists $build{$page->{file}}) {
    	  say "Building " . $page->{file} . '.';
      	my $tempname = $page->{file} . "/Page";
        my $title = $page->{name};
        my $template = $garden->get($tempname);
        my $html = $template->render(title=>$title);
        output_html($page->{file}, $html);
      }
    }
  }
}

if ($sp || $all) {
  say "Building single page version.";
  my $single = $garden->get('single_page/index');
  $garden->addGlobal('lookup', sub { return $_[0]."/content"; } );
  pop(@{$pages});
  my $single_html = $single->render(sections=>$pages);
  output_html('single_page', $single_html);
}

say "Done building pages.";

