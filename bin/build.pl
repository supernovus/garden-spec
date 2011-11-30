#!/usr/bin/perl

use Modern::Perl;
use Garden;
use JSON;

sub slurp {
  my $filename = shift;
  my $text = do { local( @ARGV, $/ ) = $filename ; <> } ;
  return $text;
}

sub output_html {
  my ($page, $html) = @_;
  my $outfile = "./spec/$page.html";
  open(my $file, '>', $outfile);
  print $file $html;
  close $file;
}

my $pages = decode_json(slurp('./src/pages.json'));
my $version = slurp('./VERSION');
my $garden = Garden->new(paths=>['./src']);

$garden->addGlobal('VERSION', $version); 

my $toc = 0; ## Build table of contents?
my $sp  = 0; ## Build single page?
my $all = 0; ## Build ALL pages?
my %build;   ## Specific pages to build.
if (@ARGV) { 
  for my $arg (@ARGV) {
    given ($arg) {
      when (/^\-t/) { $toc = 1; }
      when (/^\-s/) { $sp  = 1; }
      when (/^\-a/) { $all = 1; }
      default {
        $build{$_} = 1;
      }
    }
  }
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

