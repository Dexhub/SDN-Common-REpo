#!/usr/bin/perl
use warnings;
use strict;
use Statistics::Descriptive;

#
# Warning: untested code.
#


my $outputfile = $ARGV[1];
my @data = `cat $ARGV[0] | awk '{print \$1}' `;


open(my $fh, '>', $outputfile) or die "Could not open file '$outputfile' $!";

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@data);
$stat->sort_data();
(my $value_5, my $index_5 ) = $stat->percentile(5);
(my $value_95, my $indexi_95 ) = $stat->percentile(95);
my $min = $stat->min();
my $max = $stat->max();
my $median = $stat->median();
chomp($min,$value_5, $median,$value_95,$max);

print $fh "$min $value_5 $median $value_95 $max \n";

close $fh
