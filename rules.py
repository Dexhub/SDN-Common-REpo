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

def generator(Hosts,Switches,routefile):




#  SPLIT_TOTAL = 100
  "Create an empty network and add nodes to it."
#  net = Mininet( controller=Controller )
  #input = open(file, "r")


  print Hosts

  info( '*** Adding controller\n' )
#  net.addController( 'c0' )

  file = routefile
  
  
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
##########        Book Keeping       #####################
      # print the entire route for debugging
      for j in range(0,nodes_count):
        print Nodes[j] + "<-->",
      # Current node considering
      Prev = Nodes[i-1]
      Current = Nodes[i]
      Next = Nodes[i+1]

      print ">Current:"+ Current

##########################################################

########## FLOW RULES LOGIC ##############################
      dl_type = "0x0800"
      priority = "1"
      in_port = "1"

#      dl_src = Current.Mac()
#      dl_dst = Next.Mac()
      
#      net_src = Current.Mac()
#      dl_dst = Next.Mac()

      actions = "output:2"

#      # SET DATA LINK SOURCE
      if (Prev.find('H')!=-1): # Prev is a Host
        dl_src = Hosts[int(Prev[1:])].Mac()
        #"10.0.0."+int(Prev[1:]) # IP address of the Host
      else:
        dl_src = Switches[int(Prev[1:])].Mac()
        #dl_src = "127.0.0.1" # IP address of the Switch
#    
#      # SET DATA LINK DESTINATION
      if (Next.find('H')!=-1): # Next is a Host i.e last switch
#        dl_dst = "10.0.0."+int(Next[1:]) # IP address of the Host
        dl_dst = Hosts[int(Next[1:])].Mac()
      else:
        dl_dst = Switches[int(Next[1:])].Mac()
#        dl_dst = "127.0.0.1" # IP address of the Switch

#
#
#
#      # SET SOURCE IP ADDRESS
      if (Prev.find('H')!=-1): # Prev is a Host
        nw_src = Hosts[int(Prev[1:])].Ip()
      else:
        nw_src = Switches[int(Prev[1:])].Ip()

#    
#      # SET DESTINATION IP ADDRESS 
      if (Next.find('H')!=-1): # Next is a Host i.e last switch
        nw_dst = Hosts[int(Next[1:])].Ip()
      else:
        nw_dst = Switches[int(Next[1:])].Ip()
#      

      
      rule= "dl_type=" + dl_type
      + ", priority=" + priority
      +  ", dl_src=" + dl_src
      +  ", dl_dst=" + dl_dst
      +  ", in_port=" + in_port
      +  ", nw_src=" + nw_src
      +  ", nw_dst=" + nw_dst
      +  ", actions=" + actions

      print "=======GENERATED RULE======="
      print rule
      

######### OUTPUT THE RULE IN CORRESPONDING FILE #############
      rulefile = "rule"+Prev[1:]
      rulefile = open(rulefile, 'a') 
      rulefile.write('\n'+rule)
      rulefile.close()


#########  MERGE  THE RULES IN A SINGLE FILE ###############  
        
  
  
#print file('test.log').read()    
######### INVOKE THE POX MODULE TO IMPLEMENT THIS FILE #####





######### CLEAN BOOK KEEPING LOGS ##########################

## Check if it is Switch or Host
#  if (Nodes[0].find('S')!=-1): # Node is a Switch
#    Node1 = Switches[int(Nodes[0][1:])-1]
#  else:
#    Node1 = Hosts[int(Nodes[0][1:])-1]
#
#  print "Node 1 :", 
#  print Node1 ,
#  
## Check if it is Switch or Host
#  if (Nodes[1].find('S')!=-1): # Node is a Switch
#    Node2 = Switches[int(Nodes[1][1:])-1]
#  else:
#    Node2 = Hosts[int(Nodes[1][1:])-1]
#
#  print "Node 2 : ",
#  print Node2
#    
#  net.addLink( Node1, Node2 )
#    
	

#info( '*** Starting network\n')
#net.start()

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




#info( '*** Running CLI\n' )
#CLI( net )

#info( '*** Stopping network' )
#net.stop()

if __name__ == '__main__':
  setLogLevel( 'info' )
  emptyNet()
