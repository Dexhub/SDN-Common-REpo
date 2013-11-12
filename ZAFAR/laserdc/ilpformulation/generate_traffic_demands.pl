#! /usr/bin/perl 

use strict;

if ($#ARGV < 2)
{
	die "usage: NUMRACKS MODEL(UNIFORM-X, CONSTANT-X) outfile\n";
}

my $numracks = $ARGV[0];
my $model = $ARGV[1];
my $outfile = $ARGV[2];

my $val = 0;

if ($model =~ /CONSTANT-(\d+)/)
{
	$val = $1;		
}
if ($model =~ /UNIFORM-(\d+)/)
{
	$val = $1;		
}


open(out,">$outfile");

for (my $i = 1; $i <= $numracks; $i++)
{
	for (my $j = 1; $j <= $numracks; $j++)
	{
		if ($i != $j)
		{
			if ($model =~/UNIFORM/)
			{
				my $demand = int(rand($val)) + 1; 
				print out "$i $j $demand\n";
			}
			else
			{
				print out "$i $j $val\n";
			}
		
		}
	}
	
}

close(out);
