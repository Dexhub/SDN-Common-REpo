#!/usr/bin/python

"""
This example shows how to create an empty Mininet object
(without a topology object) and add nodes to it manually.
"""
import linecache
import sys
import time 

from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.log import setLogLevel, info

flush = sys.stdout.flush
def emptyNet():

  "Create an empty network and add nodes to it."
net = Mininet( controller=Controller )
input = open("tree", "r")

info( '*** Adding controller\n' )
net.addController( 'c0' )


Switches = []

Hosts = []

#Logic to get the value of total number of switches and hosts
# First line contains the total number of switches
line = linecache.getline('tree', 1)
new_str = ''.join(line.split('=')[1:])
Num_Switches = int(new_str)

# Second line contains the total number of hosts
line = linecache.getline('tree', 2)
new_str = ''.join(line.split('=')[1:])
Num_Hosts = int(new_str)

#Num_Hosts = 

info( '*** Adding hosts\n' )
#Get value 100 from the file -> Host
for x in range(1, Num_Hosts+1):
  host = net.addHost( 'h'+str(x), ip='10.0.0.'+str(x))
  Hosts.append(host)

#print Hosts

info( '*** Adding switch\n' )
for x in range(1, Num_Switches+1):
  switch = net.addSwitch( 's'+str(x))
  Switches.append(switch);


info( '*** Creating links\n' )
# Logic to read from line 3 to the end of file
count = len(open('tree').readlines(  ))
print count

for num in range(3,count+1):
  line = linecache.getline('tree', num)
  Nodes = line.split(' ',3)

# Check if it is Switch or Host
  if (Nodes[0].find('S')!=-1): # Node is a Switch
    Node1 = Switches[int(Nodes[0][1:])-1]
  else:
    Node1 = Hosts[int(Nodes[0][1:])-1]

  print "Node1", 
  print Node1 
  
# Check if it is Switch or Host
  if (Nodes[1].find('S')!=-1): # Node is a Switch
    Node2 = Switches[int(Nodes[1][1:])-1]
  else:
    Node2 = Hosts[int(Nodes[1][1:])-1]

  print "Node 2 selected : ",
  print Node2
    
  net.addLink( Node1, Node2 )
    
	
info( '*** Starting network\n')
net.start()

## GENERATE IPERF TRAFFIC


print "*** testing bandwidth"
for n in range(1,Num_Hosts):
    src, dst = Hosts[ 0 ], Hosts[ n ]
    print "testing", src.name, "<->", dst.name,
    bandwidth = net.iperf( [ src, dst ] )
    print bandwidth
#    flush()
#    results[ datapath ] += [ ( n, bandwidth ) ]

print results

#for datapath in switches.keys():
#    print
#    print "*** Linear network results for", datapath, "datapath:"
#    print
#    result = results[ datapath ]
#    print "SwitchCount\tiperf Results"
#    for switchCount, bandwidth in result:
#        print switchCount, '\t\t',
#        print bandwidth[ 0 ], 'server, ', bandwidth[ 1 ], 'client'
#    print
#print

#server = Hosts[10]
#client = Hosts[15]
#server.cmd( 'iperf -s -p 5001 &' )
#waitListening( client, server, 5001 )
#result = client.cmd( 'iperf -yc -t %s -c %s' % (
#  seconds, server.IP() ) ).split( ',' )
#bps = float( result[ -1 ] )
#server.cmdPrint( 'kill %iperf' )
#
#

info( '*** Running CLI\n' )
CLI( net )

info( '*** Stopping network' )
net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  emptyNet()
