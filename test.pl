#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: test.pl
#
#        USAGE: ./test.pl
#
#  DESCRIPTION: Test perl
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 26.03.2015 20:51:34
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
#use utf8;
use 5.010;

use List::Util qw(max);
use Data::Dumper;

use Stochastic;
use Stochastic::Tree;

my $t = Stochastic->new();

my $json;
open( my $f, "<", 'stochastic.json');
while(<$f>){
	$json .= $_;
}
$t->set_tree( Stochastic::Tree->create_from_json($json) );

my $a=1;
foreach $a ( (1,2,3) x 100 ){
	my $p = $t->get_prediction();
	
	my $d = $p-1;
	$d = 3 if $d == 0;

	my $wdl;
	if ( $a == $d ){
		$wdl = 'draw';
	} elsif ( ( $a == 1 && $d == 2 ) || ($a == 2 && $d == 3) || ( $a == 3 && $d == 1 ) ){
		$wdl = 'win';
	} else {
		$wdl = 'lose';
	}

	$t->set_result($wdl,$a);
	say $wdl;
}

my $json = $t->get_tree->serialize_to_json();
open( my $f, '>', 'stochastic.json' );
print $f $json;
close $f;



