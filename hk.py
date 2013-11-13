#!/usr/bin/python

"""
This example shows how to create an empty Mininet object
(without a topology object) and add nodes to it manually.
"""
import linecache
import sys

from time import sleep
from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.log import setLogLevel, info

def emptyNet():

  "Create an empty network and add nodes to it."
net = Mininet( controller=Controller )
#input = open(file, "r")

info( '*** Adding controller\n' )
net.addController( 'c0' )

file = str(sys.argv[1])

print file
Switches = []

Hosts = []

#Logic to get the value of total number of switches and hosts
# First line contains the total number of switches
line = linecache.getline(file, 1)
new_str = ''.join(line.split('=')[1:])
Num_Switches = int(new_str)

# Second line contains the total number of hosts
line = linecache.getline(file, 2)
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
count = len(open(file).readlines(  ))
print count,

for num in range(3,count+1):
  line = linecache.getline('tree', num)
  Nodes = line.split(' ',3)

# Check if it is Switch or Host
  if (Nodes[0].find('S')!=-1): # Node is a Switch
    Node1 = Switches[int(Nodes[0][1:])-1]
  else:
    Node1 = Hosts[int(Nodes[0][1:])-1]

  print "Node 1 :", 
  print Node1 ,
  
# Check if it is Switch or Host
  if (Nodes[1].find('S')!=-1): # Node is a Switch
    Node2 = Switches[int(Nodes[1][1:])-1]
  else:
    Node2 = Hosts[int(Nodes[1][1:])-1]

  print "Node 2 : ",
  print Node2
    
  net.addLink( Node1, Node2 )
    
	

info( '*** Starting network\n')
net.start()

# Logic to fetch the values from traffic matrix and call sleep for specific threads.
# step 1 run a loop and fetch values for the first 5 lines of traffic matrix
print "***STARTING!!"
#Hosts[0].cmd('sleep(1); wget h2:~/10000bytes copiedfile')
print "***STOPPING!!"
#for num in range (1, 6):
#  line = linecache.getline('traffic', num)
#  parts = line.split(' ',3)
#  command = 'sleep('+ str(parts[0]) + '); wget '+ str(parts[1])
#  parts[1].cmd('sleep(parts[0]);wget ');
#  print timing




info( '*** Running CLI\n' )
CLI( net )

info( '*** Stopping network' )
net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  emptyNet()
