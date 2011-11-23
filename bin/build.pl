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
my $garden = Garden->new(paths=>['./src']);

say "Building table of contents.";
my $tocpage = $garden->get('index');
my $tochtml = $tocpage->render(sections=>$pages);
output_html('index', $tochtml);

for my $section (@{$pages}) {
  for my $page (@{$section->{pages}}) {
    if (exists $page->{file}) {
  	  say "Building " . $page->{file} . '.';
    	my $tempname = $page->{file} . "/Page";
      my $title = $page->{name};
      my $template = $garden->get($tempname);
      my $html = $template->render(title=>$title);
      output_html($page->{file}, $html);
    }
  }
}
say "Done building pages.";

