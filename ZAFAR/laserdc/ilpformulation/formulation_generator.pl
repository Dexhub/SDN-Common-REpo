#! /usr/bin/perl 
use strict;

require "utils.pl";

if ($#ARGV < 0)
{
	die "usage: config\n";
}

my $configfile = $ARGV[0];


my  ($numracks,$numfsosperrack, $trafficdemands,$linkcap,$formulationfile) = read_config($configfile);

my $demands = read_traffic_demands($trafficdemands);

my $linkactivevar = "d";
my $flowedgevar = "f";
my $admittedtrafficvar = "t";

open(out,">$formulationfile") or die "cant open $formulationfile\n";

print out "Maximize\n Cost:   TotalAdmitted \n";

print out "Subject To\n";


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


## Flow sanity -- flow is only feasible if link is active
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoi"."_"."$rackfsoj";
					print out  "LinkSanityUB_$rackfsoi"."_$rackfsoj".":   ";
					## sum of flows over all i-e pairs must be less than capacity times zero-1 factor
					my $demandsrc = "";
					my $firstflag = 0;
					foreach $demandsrc (keys %{$demands})
					{
						my $demanddst = "";
						foreach $demanddst (keys %{$demands->{$demandsrc}})
						{
							my $srcdst = "$demandsrc"."_"."$demanddst";
							my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoi"."_"."$rackfsoj";
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
					print out " - $linkcap $thislinkactivevar <= 0\n";
	
				}
			}
		}
	}
} 

 

## Flow conservation per interior rack
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	my $demandsrc = "";	
	foreach $demandsrc (keys %{$demands})
	{
		my $demanddst = "";
		foreach $demanddst (keys %{$demands->{$demandsrc}})
		{
			my $srcdst = "$demandsrc"."_"."$demanddst";
			if ($racki != $demandsrc and $racki != $demanddst)
			{
				print out "InteriorConservation.$srcdst.$racki: ";

				my $firstflag = 0;
				## Total incoming flow into this rack for a given commodity 
				for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
				{
					my $rackfsoi = "$racki"."_"."$fsoi";
					for (my $rackj = 1; $rackj <= $numracks; $rackj++)
					{
						if ($racki != $rackj)
						{
							for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
							{
								my $rackfsoj = "$rackj"."_"."$fsoj";
								my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoj"."_"."$rackfsoi";
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
					}
				}

				## Total outgoing flow for this rack 
				for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
				{
					my $rackfsoi = "$racki"."_"."$fsoi";
					for (my $rackj = 1; $rackj <= $numracks; $rackj++)
					{
						if ($racki != $rackj)
						{
							for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
							{
								my $rackfsoj = "$rackj"."_"."$fsoj";
								my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoi"."_"."$rackfsoj";
								print out " - $thisflowvar ";
							}
						}
					}
				}
						
				print out " = 0 \n";


			}
		}
	}

}


## Flow conservation for ingress rack 
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	my $demandsrc = $racki;
	my $demanddst = "";
	## for each dst rack, total outgoing is what is admitted for that guy
	foreach $demanddst (keys %{$demands->{$demandsrc}})
	{
		my $srcdst = "$demandsrc"."_"."$demanddst";
		my $thisadmittedvar = "$admittedtrafficvar"."_"."$srcdst";
		print out "IngresssConservation.$srcdst.$racki:  $thisadmittedvar ";

		## Total outgoing flow for this rack 
		for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
		{
			my $rackfsoi = "$racki"."_"."$fsoi";
			for (my $rackj = 1; $rackj <= $numracks; $rackj++)
			{
				if ($racki != $rackj)
				{
					for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
					{
						my $rackfsoj = "$rackj"."_"."$fsoj";
						my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoi"."_"."$rackfsoj";
						print out " - $thisflowvar ";
					}
				}
			}
		}
		print out " = 0 \n";

	}
}





## Flow conservation for egress rack
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $racksrc = 1; $racksrc <= $numracks; $racksrc++)
	{
		if ($racksrc != $racki)
		{
			my $demandsrc = $racksrc;
			my $demanddst = $racki;
			my $srcdst = "$demandsrc"."_"."$demanddst";
			my $thisadmittedvar = "$admittedtrafficvar"."_"."$srcdst";
			print out "EgresssConservation.$srcdst.$racki:  $thisadmittedvar ";
			## Total incoming flow for this rack 
			for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
			{
				my $rackfsoi = "$racki"."_"."$fsoi";
				for (my $rackj = 1; $rackj <= $numracks; $rackj++)
				{
					if ($racki != $rackj)
					{
						for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
						{
							my $rackfsoj = "$rackj"."_"."$fsoj";
							my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoj"."_"."$rackfsoi";
							print out " - $thisflowvar ";
						}
					}
				}
			}	
			print out " = 0 \n";
		}
	}
}





## each link can be to at most 1 receiver 
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		print out "OutLinkAssignment.$rackfsoi: " ;
		my  $firstflag = 0;
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoi"."_"."$rackfsoj";
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
		}
		print out " <= 1\n";
	}
} 





## each link can be to at most 1 sender 
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		my  $firstflag = 0;
		print out "InLinkAssignment.$rackfsoi: ";
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoj"."_"."$rackfsoi";
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
		}
		print out " <= 1\n";
	}
} 




## Symmetry of links ij i'j' must be same as i'j' ij 

for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			my  $firstflag = 0;
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoj"."_"."$rackfsoi";
					my $thislinkactivevarrev = "$linkactivevar".""."_$rackfsoi"."_"."$rackfsoj";
					print out "SymmetricLinkAssignment.$rackfsoi.$rackfsoj: $thislinkactivevar - $thislinkactivevarrev = 0 \n"
				}
			}
		}
	}
} 


## Bounds 

## Each flow variable must be positive 
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoi"."_"."$rackfsoj";
					## sum of flows over all i-e pairs must be less than capacity times zero-1 factor
					my $demandsrc = "";
					my $firstflag = 0;
					foreach $demandsrc (keys %{$demands})
					{
						my $demanddst = "";
						foreach $demanddst (keys %{$demands->{$demandsrc}})
						{
							my $srcdst = "$demandsrc"."_"."$demanddst";
							my $thisflowvar = "$flowedgevar"."_$srcdst"."_$rackfsoi"."_"."$rackfsoj";
							print out "LBFlow.$thisflowvar:   $thisflowvar >= 0\n";
							print out "UBFlow.$thisflowvar:   $thisflowvar <= $linkcap\n";
						}
					}
				}
			}
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
			print out "AcceptedLB.$thisadmittedvar:   $thisadmittedvar >= 0\n";
			print out "AcceptedUB.$thisadmittedvar:   $thisadmittedvar <= $thisdemand\n";
		}
	}
} 




## each flow on each edge must be non zero and less than capacity



## Binaries
print out "Binaries\n";

## Each link variable must be 0 or 1
for (my $racki = 1; $racki <= $numracks; $racki++)
{
	for (my $fsoi = 1; $fsoi <= $numfsosperrack; $fsoi++)
	{
		my $rackfsoi = "$racki"."_"."$fsoi";
		for (my $rackj = 1; $rackj <= $numracks; $rackj++)
		{
			if ($racki != $rackj)
			{
				for (my $fsoj = 1; $fsoj <= $numfsosperrack; $fsoj++)
				{
					my $rackfsoj = "$rackj"."_"."$fsoj";
					my $thislinkactivevar = "$linkactivevar".""."_$rackfsoi"."_"."$rackfsoj";
					print out "$thislinkactivevar\n";
				}
			}
		}
	}
} 








print out "End\n";
close(out); 
