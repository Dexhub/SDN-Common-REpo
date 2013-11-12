#! /usr/bin/perl 

use strict;
sub read_config_steiner
{
	my $file = shift;
	open(f,"<$file") or die "cant open the config file\n";
	my $data = "";
	my $numracks = "";
	my $machinesperrack = "";
	my $numflexperrack = "";
	my $numsteiner = "";
	my $steinerdegree = "";
	my $trafficdemands = "";
	my $linkcap = "";
	my $lpformulationfile = "";
	my $ilpformulationfile = "";
	while ($data  = <f>)
	{
		chomp($data);
		if ($data =~ /NUMRACKS\s+(\d+)/)
		{
			$numracks = $1;
		}
		if ($data =~ /MACHINESPERRACK\s+(\d+)/)
		{
			$machinesperrack = $1;
		}
		if ($data =~ /NUMFLEXPERRACK\s+(\d+)/)
		{
			$numflexperrack = $1;
		}
		if ($data =~ /NUMSTEINER\s+(\d+)/)
		{
			$numsteiner = $1;
		}
		if ($data =~ /STEINERDEGREE\s+(\d+)/)
		{
			$steinerdegree = $1;
		}
		if ($data =~ /DEMANDS\s+(.*)/)
		{
			$trafficdemands = $1;
		}
		if ($data =~ /LINKCAPACITY\s+(\d+)/)
		{
			$linkcap = $1;
		}
		if ($data =~ /ILPFORMULATIONFILE\s+(.*)/)
		{
			$ilpformulationfile = $1;
		}
	
		if ($data =~ /LPFORMULATIONFILE\s+(.*)/)
		{
			$lpformulationfile = $1;
		}
			
	}
	return ($numracks,$machinesperrack, $numflexperrack, $numsteiner, $steinerdegree, $trafficdemands,$linkcap,$ilpformulationfile, $lpformulationfile);
}

sub read_config
{
	my $file = shift;
	open(f,"<$file") or die "cant open the config file\n";
	my $data = "";
	my $numracks = "";
	my $numfsosperrack = "";
	my $trafficdemands = "";
	my $linkcap = "";
	my $formulationfile = "";
	while ($data  = <f>)
	{
		chomp($data);
		if ($data =~ /NUMRACKS\s+(\d+)/)
		{
			$numracks = $1;
		}
		if ($data =~ /NUMFSOS\s+(\d+)/)
		{
			$numfsosperrack = $1;
		}
		if ($data =~ /DEMANDS\s+(.*)/)
		{
			$trafficdemands = $1;
		}
		if ($data =~ /LINKCAPACITY\s+(\d+)/)
		{
			$linkcap = $1;
		}
		if ($data =~ /FORMULATIONFILE\s+(.*)/)
		{
			$formulationfile = $1;
		}
			
	}
	return ($numracks,$numfsosperrack, $trafficdemands,$linkcap,$formulationfile);
}

sub read_traffic_demands
{
	my $file = shift;
	my %TM = ();
	
	open(f,"<$file") or die "cant open the demands file $file\n";
	my $data = "";
	while ($data  = <f>)
	{
		chomp($data);
		my ($src,$dst,$demand)= split(/\s+/,$data);
		$TM{$src}->{$dst} = $demand;
	}
	return \%TM;	
}

1;
