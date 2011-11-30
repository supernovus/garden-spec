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

my $only; ## If this is set we only build this page.
if (@ARGV) { $only = $ARGV[0]; }

if (!defined $only) {
  say "Building table of contents.";
  my $tocpage = $garden->get('index');
  my $tochtml = $tocpage->render(sections=>$pages);
  output_html('index', $tochtml);
}

for my $section (@{$pages}) {
  for my $page (@{$section->{pages}}) {
    if (exists $page->{file}) {
      if (defined $only && $only ne $page->{file}) { next; }
  	  say "Building " . $page->{file} . '.';
    	my $tempname = $page->{file} . "/Page";
      my $title = $page->{name};
      my $template = $garden->get($tempname);
      my $html = $template->render(title=>$title);
      output_html($page->{file}, $html);
    }
  }
}

say "Building single page version.";
my $single = $garden->get('single_page/index');
$garden->addGlobal('lookup', sub { return $_[0]."/content"; } );
pop(@{$pages});
my $single_html = $single->render(sections=>$pages);
output_html('single_page', $single_html);

say "Done building pages.";

