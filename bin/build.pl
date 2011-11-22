#!/usr/bin/perl

use Modern::Perl;
use Garden;

my $garden = Garden->new(paths=>['./src']);
open(my $list, './src/pages.list');
my @pages = <$list>;
close $list;

for my $page (@pages) {
  chomp($page);
	say "Building $page.";
	my $tempname = "$page/Layout";
  my $template = $garden->get($tempname);
  my $outfile = "./spec/$page.html";
  open(my $html, '>', $outfile);
  print $html $template->render();
  close $html;
}
say "Done building pages.";

