#! /usr/bin/perl -w

use strict;
use warnings;
use HTML::Entities;
use utf8;
use open ':std', ':encoding(utf8)';
$| = 1;

############################################################################
# A script to crawl match reports from kicker.de as nice and handy xml-files
# Written by Simon Meier-Vieracker (fussballlinguistik.de
############################################################################

my $url;
my @urls;
my $title;
my $date;
my $datePublished;
my $team1;
my $team2;
my $home_goal;
my $away_goal;
my $topline;
my $head;
my $teaser;
my $article;
my $p;

my $start_url = "https://www.kicker.de/bundesliga/spieltag/" . $ARGV[0] . "/-1/0";
# --> Define the start page (to find under Liga -> Spieltag/Tabelle -> alle) 

my $path = "./results/" . $ARGV[0] . ".xml";
# --> Define path and outpute filename

############################
# no changes below this line
############################

unlink($path);
print "Hole die URLs…\n";
my $start_html = qx(curl -s $start_url);
my @lines = split /\n/, $start_html;
foreach my $line (@lines) {
	if ($line =~ m/<a class="kick__v100-gameList__gameRow__stateCell__indicator kick__v100-gameList__gameRow__stateCell__indicator--schema" href="(.+?)">/) {
		$url = "https://www.kicker.de" . $1;
		push @urls, $url;
	}
}

my $counter = 0;
my $length = scalar @urls;
open OUT, ">> $path" or die $!;
print OUT "<corpus>\n";

foreach my $url_game (@urls) {
	my $html = qx(curl -s $url_game);	

	$counter++;
	print "\rLade Nr. $counter von $length…";

	if ($html =~ /<title>(.+?)<\/title>/) {
		$title = $1;
	}
	if ($html =~ /kick__article__time">(.+?)\.(.+?)\.(.+?) - (.+?)</) {
		$date = "$3-$2-$1";
		$datePublished = $4;
	}

	print OUT "<text>
	<url>$url_game</url>
	<title>$title</title>
	<date>$date</date>
	<time>$datePublished</time>\n";

	if ($html =~ /kick__article__content__child">([\w\W]+?)<div class="kick__article__detail">/) {
		$article = $1;
	}
	my @paragraphs = split /<[hp]/, $article;
	foreach my $paragraph (@paragraphs) {
		# print OUT "START: $paragraph :END\n";
		if ($paragraph =~ />(.+?)<\/p/gs 
				&& $paragraph !~ m/kick__article__bonus-stat__key-val-b/
				&& $paragraph !~ m/kick__two__lines/
				&& $paragraph !~ m/kick__article__bonus-stat__person-name/
			) {
			$p = $1;
			$p =~ s/<.+?>//g;
			$p = decode_entities($p);
			$p =~ s/&/\&amp;/g;
			$p =~ s/[\r\n\t\f\v]//g;
			$p =~ s/^\s+|\s+$//g;
			print OUT "\t<p>$p</p>\n" if $p ne "";
		}
	}
	
	print OUT "</text>\n";
	sleep rand 3;
}

print OUT "</corpus>\n";
close OUT;
print "\nDone!\n";
