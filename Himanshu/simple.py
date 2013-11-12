#!/usr/bin/python

"""
This example shows how to create an empty Mininet object
(without a topology object) and add nodes to it manually.
"""

from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.log import setLogLevel, info

def emptyNet():

  "Create an empty network and add nodes to it."
net = Mininet( controller=Controller )

info( '*** Adding controller\n' )
net.addController( 'c0' )


Switches = []
Hosts = []

#Logic to get the value of total number of switches and hosts
#Get value 1 from the file -> Switch

info( '*** Adding hosts\n' )
#Get value 100 from the file -> Host
for x in range(1, 100):
  host = net.addHost( 'h'+str(x), ip='10.0.0.'+str(x))
  Hosts.append(host)

print Hosts

info( '*** Adding switch\n' )
for x in range(1, 2):
  switch = net.addSwitch( 's'+str(x))
  Switches.append(switch);


info( '*** Creating links\n' )
# Logic to read from line 3 to the end of file
for x in range(0, 99):
    net.addLink( Hosts[x], Switches[0] )
    
	

info( '*** Starting network\n')
net.start()

info( '*** Running CLI\n' )
CLI( net )

info( '*** Stopping network' )
net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  emptyNet()
