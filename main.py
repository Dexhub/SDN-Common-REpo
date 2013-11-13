#!/usr/bin/python

"""
This example shows how to create an empty Mininet object
(without a topology object) and add nodes to it manually.
"""
import linecache
import sys
import rules

from time import sleep
#from mininet.net
from mininet.net import Mininet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.node import Node
from mininet.log import setLogLevel, info

def emptyNet():

  "Create an empty network and add nodes to it."
net = Mininet( controller=Controller )
#input = open(file, "r")
rulesdir = "./Rules/"
info( '*** Adding controller\n' )
net.addController( 'c0' )

file = str(sys.argv[1])
rulefile = str(sys.argv[2])
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

info( '*** Adding hosts\n' )
#Get value 100 from the file -> Host
for x in range(1, Num_Hosts+1):
  host = net.addHost( 'h'+str(x), ip='10.0.0.'+str(x))
  Hosts.append(host)
#print Hosts


print "########## Experiment ##########"

#print net.hosts[0].eth0.Mac()

print "========My Hosts================"
print Hosts

info( '*** Adding switch\n' )
for x in range(1, Num_Switches+1):
  switch = net.addSwitch( 's'+str(x))
  Switches.append(switch);
#  print switch.Mac()

info( '*** Creating links\n' )
# Logic to read from line 3 to the end of file
count = len(open(file).readlines(  ))
print count,

for num in range(3,count+1):
  line = linecache.getline(file, num)
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
    
# Logic to fetch the values from traffic matrix and call sleep for specific threads.
# step 1 run a loop and fetch values for the first 5 lines of traffic matrix
#print "***STARTING!!"
#Hosts[0].cmd('sleep(1); wget h2:~/10000bytes copiedfile')
#print "***STOPPING!!"
#for num in range (1, 6):
#  line = linecache.getline('traffic', num)
#  parts = line.split(' ',3)
#  command = 'sleep('+ str(parts[0]) + '); wget '+ str(parts[1])
#  parts[1].cmd('sleep(parts[0]);wget ');
#  print timing

#print Switches
#print Hosts


file = rulefile
print "=== Generating switch rules from the file:",
print file + " ==="
# Logic to read each line will the end of file
count = len(open(file).readlines(  ))
print ">>"+str(count)

for num in range(1,count+1):
  line = linecache.getline(file, num)
  Nodes = line.split( )
  nodes_count = line.count(' ');
  # Logic for what rules to implement for each of the hosts and switches
  for i in range(1,nodes_count-1): # Run loop from the second node in the path till the second last. This is because, these are the nodes that are switches.

########        Book Keeping       #####################
    # print the entire route for debugging
    for j in range(0,nodes_count):
      print Nodes[j] + "<-->",
    # Current node considering
    Prev = Nodes[i-1]
    Current = Nodes[i]
    Next = Nodes[i+1]

    print "Current:"+ Current

########################################################

######## FLOW RULES LOGIC ##############################
    dl_type = "0x0800"
    priority = 1
    in_port = 1

    actions = "output:2"

     # SET SOURCE IP ADDRESS
    if (Current.find('H')!=-1): # Prev is a Host
      #dl_src = Hosts[int(Current[1:])].Mac()
       dl_src = "10.0.0."+str(int(Current[1:])) # IP address of the Host
    else:
      #dl_src = Switches[int(Current[1:])].Mac()
      dl_src = "127.0.0.1" # IP address of the Switch
   
     # SET DESTINATION IP ADDRESS 
    if (Next.find('H')!=-1): # Next is a Host i.e last switch
      dl_dst = "10.0.0."+str(int(Next[1:])) # IP address of the Host
      #dl_dst = Hosts[int(Next[1:])].Mac()
    else:
      #dl_dst = Switches[int(Next[1:])].Mac()
      dl_dst = "127.0.0.1" # IP address of the Switch


     # SET DATA LINK SOURCE
    if (Current.find('H')!=-1): # Prev is a Host
      #nw_src = Hosts[int(Current[1:])].Ip()
      value = int(Current[1:])
      nw_src = str(hex(value % 16))[2:].zfill(2)
      value = value / 16
    
      for i in 1,2,3,4,5:
        nw_src = str(hex(value % 16))[2:].zfill(2) + "::" + nw_src
        value = value / 16
    else:
      # wrong => Clean
      value = int(Next[1:])
      nw_src = str(hex(value % 16))[2:].zfill(2)
      value = value / 16
    
      for i in 1,2,3,4,5:
        nw_src = str(hex(value % 16))[2:].zfill(2)+ "::" + nw_src
        value = value / 16
      #nw_src = Switches[int(Current[1:])].Ip()
#      nw_src = Switches[int(Current[1:])].Ip()
  
  # SET DATA LINK DESTINATION
    if (Next.find('H')!=-1): # Next is a Host i.e last switch
      value = int(Next[1:])
      nw_dst = str(hex(value % 16))[2:].zfill(2)
      value = value / 16
    
      for i in 1,2,3,4,5:
        nw_dst = str(hex(value % 16))[2:].zfill(2) + "::" + nw_dst
        value = value / 16
    else:
      # wrong => Clean
      value = int(Next[1:])
      nw_dst = str(hex(value % 16))[2:].zfill(2)
      value = value / 16
    
      for i in 1,2,3,4,5:
        nw_dst = str(hex(value % 16))[2:].zfill(2) + "::" + nw_dst
        value = value / 16
      #nw_src = Switches[int(Current[1:])].Ip()
 #     nw_dst = Switches[int(Next[1:])].Ip()
      


#nw_dst = Hosts[int(Next[1:])].Ip()
#    else:
#      nw_dst = Switches[int(Next[1:])].Ip()
     
    rule= "dl_type="+dl_type+", priority="+str(priority)+", dl_src="+dl_src+", dl_dst="+dl_dst+", in_port="+str(in_port)+", nw_src="+nw_src+", nw_dst="+nw_dst+", actions="+actions

    print "=======GENERATED RULE======="
    print rule


######### OUTPUT THE RULE IN CORRESPONDING FILE #############

    rulefile = rulesdir+"rule"+Prev[1:]+".txt"
    rulefile = open(rulefile, 'a')
    rulefile.write('\n'+rule)
    rulefile.close()
     


#########  MERGE  THE RULES IN A SINGLE FILE ############### 

FILES = len(Switches)
print "Total Files Generated:"+str(FILES)
combined = rulesdir+"Allrules.txt"
combined = open(combined, 'w')
for i in range(1,FILES+1):
  rulefile = rulesdir+"rule"+str(i)+".txt"
  rulefile = open(rulefile, 'r')
  combined.write("\n Rules for Switch"+str(i))
  combined.write(rulefile.read())
  rulefile.close()
combined.close()


info( '*** Starting network\n')
net.start()

info( '*** Running CLI\n' )
#CLI( net )

info( '*** Stopping network' )
net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  emptyNet()
