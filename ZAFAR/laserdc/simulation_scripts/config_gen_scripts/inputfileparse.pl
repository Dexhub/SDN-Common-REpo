#! /usr/bin/perl

use strict;



## map traffic class to policy chain
## Ingress Type host, Egress Type host,
## Required Type of middlebox processing = chain DiffMboxTypes
sub read_policy_chains
{
	my $filename = shift;
	open(f,"<$filename") or die "cant read policy file $filename\n";
	my $classid = 1;
	my %ClassID2PolicyChain = ();
	my %ClassID2Hosts = ();
	my %ClassID2Volume = ();
	my $data = "";
	while ($data = <f>)
	{
		chomp($data);
		if ($data =~ /^#/)
		{
			## ignore comment line
		}
		else
		{	
			my ($host1,$host2,$policychain,$volume) = split(/\s+/,$data);
			$ClassID2PolicyChain{$classid} = $policychain;
			$ClassID2Hosts{$classid} = "$host1;$host2";
			$ClassID2Volume{$classid} = $volume;
#			print "Here $classid $host1 $host2 $policychain\n";
			$classid++;
		}
	}
	return (\%ClassID2PolicyChain, \%ClassID2Hosts,\%ClassID2Volume);
}

## first entry is a switch, other entry can be switch, host or mbox
sub validate_topology_input
{
	my $node1 = shift;
	my $node2 = shift;
	if ($node1 =~ /^S\d+$/)
	{
		if ($node2 =~ /^S\d+$/ or $node2 =~ /^M\d+$/ or $node2 =~ /^H\d+$/)
		{
			return 1;
		}
	}
	return 0;
}

## Sequentially numbered starting from switches, then boxes, then hostnodes
sub get_nodename2id
{
	my $nodename = shift;
	my $hashref = shift;
	my $numswitches = shift;
	my $numhosts=  shift;
	if (defined $hashref->{$nodename})
	{
		return $hashref->{$nodename};
	}
	else
	{
		if ($nodename =~ /^S(\d+)$/)
		{
			return $1;
		}	
		elsif ($nodename =~ /^H(\d+)$/)
		{
			return $numswitches + $1;
		}
	}
	print "Zafar\n";
	
}

## three types of nodes 
## Host, Switch, Middlebox 
sub read_topology
{
	my $filename = shift;
	open(f,"<$filename") or die "cant read topology file $filename\n";
	my $globalnodeid = 1;
	my %NodeNametoID= ();
	my %NodeIDtoName = ();
	my %TopologyName = ();
	my %TopologyID = ();
	my $NumSwitches = 0;
	my $NumHostNodes = 0;
	my $data = "";
	while ($data = <f>)
	{
		chomp($data);
		if ($data =~ /^#/)
		{
			## ignore comment line
		}
		elsif ($data=~ /NUMSWITCHES=(\d+)/)
		{
			$NumSwitches = $1;
		}
		elsif ($data=~ /NUMHOSTNODES=(\d+)/)
		{
			$NumHostNodes = $1;
		}
		else
		{
			my ($node1,$node2,$cost) = split(/\s+/,$data);
			if (validate_topology_input($node1,$node2) == 1)
			{
				my $nodeid1 = get_nodename2id($node1,\%NodeNametoID,$NumSwitches,$NumHostNodes); 
				my $nodeid2 = get_nodename2id($node2,\%NodeNametoID,$NumSwitches,$NumHostNodes); 
				$NodeNametoID{$node1} = $nodeid1;
				$NodeNametoID{$node2} = $nodeid2;
				#print "Came here name=$node1 id=$nodeid1\n";
				$NodeIDtoName{$nodeid1} = $node1;
				$NodeIDtoName{$nodeid2} = $node2;
				## assume symmetric link
				## by name
				$TopologyName{$node1}->{$node2}  = $cost;
				$TopologyName{$node2}->{$node1}  = $cost;
				## by nodeid
				$TopologyID{$nodeid1}->{$nodeid2}  = $cost;
				$TopologyID{$nodeid2}->{$nodeid1}  = $cost;
			}
		}
	}
	return (\%TopologyName,\%TopologyID,\%NodeNametoID,\%NodeIDtoName, $NumSwitches,$NumHostNodes);
}

## map each middlebox to its  type, resource cap  
sub middlebox_inventory
{
	my $filename = shift;
	open(f,"<$filename") or die "cant read mboxinventory file $filename\n";
	my %MboxName2Type = ();
	my %MboxType2Set = ();
	my %MboxResources = ();
	my $data = "";
	while ($data = <f>)
	{
		chomp($data);
		if ($data =~ /^#/)
		{
			## ignore comment line
		}
		else
		{
			my ($mboxid,$type,$resources) = split(/\s+/,$data);
			$MboxName2Type{$mboxid} = $type;
			$MboxType2Set{$type}->{$mboxid} = 1;
			$MboxResources{$mboxid}  = $resources;
		}
	}
	return \%MboxName2Type, \%MboxType2Set, \%MboxResources;

}
##  how many rules does each switch need to support a specific physical chain
sub switch_inventory
{
	my $filename = shift;
	open(f,"<$filename") or die "cant read switchinventory file $filename\n";
	my %SwitchResources = ();
	my $data = "";
	while ($data = <f>)
	{
		chomp($data);
		if ($data =~ /^#/)
		{
			## ignore comment line
		}
		else
		{
			my ($switchid,$resources) = split(/\s+/,$data);
			#print "here $switchid $resources\n";
			$SwitchResources{$switchid}  = $resources;
		}
	}
#	print "HERE S1 ".$SwitchResources{"S1"}."\n";
	return \%SwitchResources;
}

sub get_canonical_linkname
{
	my $src = shift;
	my $dst = shift;

	my $tmpsrc = $src;
	my $tmpdst = $dst;
	if ($src =~ /^S(\d+)/)
	{
		my $srcid = $1;
 		if ($dst =~ /^S(\d+)/)
		{
			my $dstid = $1;
			## if destination is smaller then swap
			if ($dstid < $srcid)
			{
				$tmpsrc = $dst;
				$tmpdst = $src;
			}
		}
		else
		{
			## do nothing, we are fine if src is a switch and dst isnt
		}
	}
	## in this case, since src is not a switch dst has to be a switch so swap
	else 
	{
 		if ($dst =~ /^S(\d+)/)
		{
			$tmpsrc = $dst;
			$tmpdst = $src;
		}
		else
		{
			print "Error -- this is not possible Src = $src Dst = $dst\n";
		}

	}
	my $result =  "Link$tmpsrc$tmpdst";
	return $result;

}

sub read_link_capacities
{
	my $linkfile = shift;
	my %LinkCaps = ();
	open(f,"$linkfile") or die "cant open link capacitieis file $linkfile\n";
	my $data = "";
	while ($data = <f>)
	{
		chomp($data);

		my ($src,$dst,$cap) = split(/\s+/,$data);
		my $linkid = get_canonical_linkname($src,$dst);
		$LinkCaps{$linkid} = $cap;	
	}		
	return \%LinkCaps;
}

1;
