#! /usr/bin/perl 
use strict;

require "utils.pl";

if ($#ARGV < 0)
{
	die "usage: config\n";
}

my $configfile = $ARGV[0];


my  ($numracks,$nummachinesperrack, $numflexperrack, $numsteiner, $steinerdegree, $trafficdemands,$linkcap,$ilpformulationfile,$lpformulationfile) = read_config_steiner($configfile);

print "HERE racks=$numracks machines = $nummachinesperrack flex=$numflexperrack steiner=$numsteiner,$steinerdegree\n"; 

my $demands = read_traffic_demands($trafficdemands);

my $linkactivevar = "L";
my $flowedgevar = "F";
my $admittedtrafficvar = "t";

open(out,">$ilpformulationfile") or die "cant open $ilpformulationfile\n";

print out "Maximize\n Cost:   TotalAdmitted \n";

print out "Subject To\n";


## NODES 1..$numracks are ToR and $numracks -- $numracks+$numsteiner are Steiner


## Model objective function 
print out  "TotalFlow: TotalAdmitted ";
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $rackj = 1; $rackj <= $numracks; $rackj++)
	{
		if ($racki != $rackj)
		{
			my $thisadmittedvar = "$admittedtrafficvar"."_"."$racki"."_"."$rackj"; 
			print out " - $thisadmittedvar";
		}
	}
} 
print out " = 0\n";

my $numnodes = $numracks + $numsteiner;


## Flow sanity -- flow is only feasible if there is sufficient capacity between the pair of nodes?
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		my $numlinksactivevar = "$linkactivevar".""."_$nodei"."_"."$nodej";
		print out  "LinkSanityUBDirect_$nodei"."_$nodej".":   ";
		## sum of routed flows over all demands  must be less than capacity times numlinks factor
		my $demandsrc = "";
		my $firstflag = 0;
		foreach $demandsrc (keys %{$demands})
		{
			my $demanddst = "";
			foreach $demanddst (keys %{$demands->{$demandsrc}})
			{
				my $srcdst = "$demandsrc"."_"."$demanddst";
				my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodei"."_"."$nodej";
				if ($firstflag == 0)
				{
					print out "$thisflowvar ";
					$firstflag = 1;
				}		
				else
				{
					print out " + $thisflowvar ";
				}
			}
		}
		print out " - $linkcap $numlinksactivevar <= 0\n";
	
	}
} 

## Flow conservation per interior NODE (which could be rack or steiner)
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	my $demandsrc = "";	
	foreach $demandsrc (keys %{$demands})
	{
		my $demanddst = "";
		foreach $demanddst (keys %{$demands->{$demandsrc}})
		{
			my $srcdst = "$demandsrc"."_"."$demanddst";
			if ($nodei != $demandsrc and $nodei != $demanddst)
			{
				print out "InteriorConservation.$srcdst.$nodei: ";

				my $firstflag = 0;
				## Total incoming flow into this rack for a given commodity 
				for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
				{
					if ($nodei != $nodej)
					{
						my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodej"."_"."$nodei";
						if ($firstflag == 0)
						{		
							$firstflag = 1;
							print out "$thisflowvar ";
						}
						else
						{
							print out " + $thisflowvar ";
						}
					}
				}
				## Total outgoing flow for this rack 
				for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
				{
					if ($nodei != $nodej)
					{
						my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodei"."_"."$nodej";
						print out " - $thisflowvar ";
					}
				}
				print out " = 0 \n";
			}
		}
	}
}


## Flow conservation for ingress rack 
for (my $nodei = 1; $nodei <= $numracks; $nodei++)
{
	my $demandsrc = $nodei;
	my $demanddst = "";
	## for each dst rack, total outgoing is what is admitted for that guy
	foreach $demanddst (keys %{$demands->{$demandsrc}})
	{
		my $srcdst = "$demandsrc"."_"."$demanddst";
		my $thisadmittedvar = "$admittedtrafficvar"."_"."$srcdst";
		print out "IngressConservation.$srcdst.$nodei:  $thisadmittedvar ";

		## Total outgoing flow for this rack 
		for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
		{
			if ($nodei != $nodej)
			{
				my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodei"."_"."$nodej";
				print out " - $thisflowvar ";
			}
		}
		print out " = 0 \n";
	}
}


## Flow conservation for egress rack
for (my $nodei = 1; $nodei <= $numracks; $nodei++)
{
	for (my $nodesrc = 1; $nodesrc <= $numnodes; $nodesrc++)
	{
		if ($nodesrc != $nodei)
		{
			my $demandsrc = $nodesrc;
			my $demanddst = $nodei;
			my $srcdst = "$demandsrc"."_"."$demanddst";
			my $thisadmittedvar = "$admittedtrafficvar"."_"."$srcdst";
			print out "EgressConservation.$srcdst.$nodei:  $thisadmittedvar ";
			## Total incoming flow for this rack 
			for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
			{
				if ($nodei != $nodej)
				{
					my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodej"."_"."$nodei";
					print out " - $thisflowvar ";
				}
			}	
			print out " = 0 \n";
		}
	}
}


## Degree bounds for the nodes
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	print out "LinkAssignment.$nodei: " ;
	my  $firstflag = 0;
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		if ($nodei != $nodej)
		{
			my $thislinkactivevar = "$linkactivevar".""."_$nodei"."_"."$nodej";
			if ($firstflag == 0)
			{
				print out "$thislinkactivevar";
				$firstflag = 1;
			}
			else
			{
				print out " + $thislinkactivevar";
			}
		}
	}
	## RAKCS AND STEINER HAVE DIFF FLEX DEGREE ..
	my $degree = ($nodei <= $numracks)? $numflexperrack:$steinerdegree;
	print out " <= $degree\n";
} 


## Symmetry of links ij i'j' must be same as i'j' ij 
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		my  $firstflag = 0;
		if ($nodei != $nodej)
		{
			my $thislinkactivevar = "$linkactivevar".""."_$nodej"."_"."$nodei";
			my $thislinkactivevarrev = "$linkactivevar".""."_$nodei"."_"."$nodej";
			print out "SymmetricLinkAssignment.$nodei.$nodej: $thislinkactivevar - $thislinkactivevarrev = 0 \n"
		}
	}
} 

print out "Bounds\n";

## Each flow variable must be positive 
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		if ($nodei != $nodej)
		{
			my $thislinkactivevar = "$linkactivevar".""."_$nodei"."_"."$nodej";
			my $demandsrc = "";
			my $firstflag = 0;
			foreach $demandsrc (keys %{$demands})
			{
				my $demanddst = "";
				foreach $demanddst (keys %{$demands->{$demandsrc}})
				{
					my $srcdst = "$demandsrc"."_"."$demanddst";
					my $thisflowvar = "$flowedgevar"."_$srcdst"."_$nodei"."_"."$nodej";
					my $maxcap = $numflexperrack * $linkcap;
					print out " 0 <= $thisflowvar <= $maxcap\n";
				}
			}
		}
	}
} 

## Each link variable cannot be more than maxdegree 
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	my $degreei  = ($nodei <= $numracks)? $numflexperrack:$steinerdegree;
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		if ($nodei != $nodej)
		{
			my $thislinkactivevar = "$linkactivevar".""."_$nodei"."_"."$nodej";
			my $degreej  = ($nodej <= $numracks)? $numflexperrack:$steinerdegree;
			my $maxdeg = ($degreei < $degreej)? $degreei:$degreej;
			print out " 0 <= $thislinkactivevar <= $maxdeg\n";
		}
	}
} 


## Each admitted flow must be less than the demand
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $rackj = 1; $rackj <= $numracks; $rackj++)
	{
		if ($racki != $rackj)
		{
			my $thisadmittedvar = "$admittedtrafficvar"."_"."$racki"."_"."$rackj"; 
			my $thisdemand = $demands->{$racki}->{$rackj};
			print out " 0 <=  $thisadmittedvar <= $thisdemand\n";
		}
	}
} 

close(out);
system("cp $ilpformulationfile $lpformulationfile");

open(out,">>$ilpformulationfile") or die "cant open $ilpformulationfile\n";
open(out1,">>$lpformulationfile") or die "cant open $lpformulationfile\n";
## Integer vars 
print out "General\n";

## Each link variable must be 0 or 1
for (my $nodei = 1; $nodei <= $numnodes; $nodei++)
{
	for (my $nodej = 1; $nodej <= $numnodes; $nodej++)
	{
		if ($nodei != $nodej)
		{
			my $thislinkactivevar = "$linkactivevar".""."_$nodei"."_"."$nodej";
			print out "$thislinkactivevar\n";
		}
	}
} 

print out "End\n";
close(out); 

print out1 "End\n";
close(out1); 
