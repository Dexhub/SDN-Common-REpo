#include "config.h"
#include <sstream>
#include <string.h>
#include <strstream>
#include <iostream>
#include <fstream>
#include <cstring>
#include <math.h>
#include <queue>
#include "network.h"
#include "randomqueue.h"
#include "pipe.h"
#include "eventlist.h"
#include "logfile.h"
#include "loggers.h"
#include "clock.h"
//Vyas
#include "cleanup_clock.h"
#include "mtcp.h"
#include "exoqueue.h"

using namespace std;

//Vyas -- make these global
  EventList eventlist;
TcpRtxTimerScanner tcpRtxScanner(timeFromMs(10), eventlist);
set<string> deletedflows;
bool notdeleted(string s)
{
	if (deletedflows.find(s) == deletedflows.end())
		return true;
	return false;
}

string ntoa(double n);
string itoa(uint64_t n);

// Simulation params
simtime_picosec RTT1=timeFromMs(0.05);


//Vyas
priority_queue<TcpTmp,vector<TcpTmp>,CompareTcpSrc> TcpSrcesToDelete; 

simtime_picosec RTT2=timeFromMs(500);

#define TCP_1 1
#define TCP_2 1

linkspeed_bps SERVICE1 = speedFromMbps(30.0);//NUMFLOWS * targetwnd/timeAsSec(RTT1));
linkspeed_bps SERVICE2 = speedFromPktps(100);//NUMFLOWS * targetwnd/timeAsSec(RTT2));

#define RANDOM_BUFFER 3

#define FEEDER_BUFFER 100 

mem_b BUFFER1=memFromPkt(RANDOM_BUFFER+8);//NUMFLOWS * targetwnd);
mem_b BUFFER2=memFromPkt(RANDOM_BUFFER+50);//NUMFLOWS * targetwnd);



const int MAX_CHARS_PER_LINE = 5120;
const int MAX_TOKENS_PER_LINE = 20;
const char* const DELIMITER = " ";
const char* const DELIMITER1 = "";
const char* const DELIMITER2 = ",";





void exit_error(char* progr){
  cout << "Usage " << progr << " topology_file route_file  hotspot/uniform total_sim_time random_seed\n" << endl;
  exit(1);
}

int main(int argc, char **argv) {
  eventlist.setEndtime(timeFromSec(atoi(argv[4])));
  Clock c(timeFromSec(50/100.), eventlist);
  CleanupClock cleanc(timeFromMs(50), eventlist);

if (argc<5){
      exit_error(argv[0]);
  }





  int sim_time = atoi(argv[4]) - 1;
  ifstream fin;
  ifstream routingin;
  fin.open(argv[1]); // open a file
  routingin.open(argv[2]);
  if (!fin.good()) 
    return 1; // exit if file not found
 
  if (!routingin.good()) 
    return 1; // exit if file not found


  // read each line of the file
  int i;
  string queue1 = "";
  string queue2 = "";
  string node1 = "";
  string node2 = "";
  string queuename = "";
  string queuename1 = "";   
  


  srand(atof(argv[5]));
  Pipe pipe1(RTT1, eventlist); pipe1.setName("pipe1");                                      
  Pipe pipe2(RTT2, eventlist); pipe2.setName("pipe2");  

  // Added by zafar
  map<string,Queue*> myvars;


  Queue* pqueue1;
  Queue* pqueue2;


  TcpSrc* tcpSrc;
  TcpSink* tcpSnk;
  route_t* routeout;
  route_t* routein;
  //route_t* routeout_dup;
  //route_t* routein_dup;
  

  double extrastarttime;
  double random_toss;
  string flowlabel = "";


  
 char buf[MAX_CHARS_PER_LINE];
 //fin.getline(buf, MAX_CHARS_PER_LINE);
 // Read the topology file
 while (fin.getline(buf, MAX_CHARS_PER_LINE)) // !fin.eof())
  {
    //read an entire line into memory
    int n = 0; // a for-loop index   
    char* token[MAX_TOKENS_PER_LINE] = {};
    token[0] = strtok(buf, DELIMITER);
    if (token[0]) // zero if line is blank
    {
      for (n = 1; n < MAX_TOKENS_PER_LINE; n++)
      {
        token[n] = strtok(0, DELIMITER); // subsequent tokens
        if (!token[n]) break; // no more tokens
      }
    }

     for (i = 0; i < n-1; i++) 
     { 
		
	char* test = (token[i]+sizeof(char));
	//cout << test;  
	if (i==0)
        {
		queue1 = test;
        }
	if (i==1 and token[i][0] != 'H') 
	{
		queue2 = test;
	}

     }        

	if (queue2 != "")
	{
  
		queuename = "S" + queue1 + "out" + "S" + queue2;
		queuename1 = "S" +  queue2 + "out" + "S" + queue1;
		pqueue1 = new Queue(SERVICE1, memFromPkt(FEEDER_BUFFER), eventlist,NULL);
		pqueue2 = new Queue(SERVICE1, memFromPkt(FEEDER_BUFFER), eventlist,NULL);
		myvars[queuename] = pqueue1;
		myvars[queuename1] = pqueue2;;

 	}

 }

/*******************************************************************************************************************/


// Now lets read the routing file and create routes and tcp src and sink accordingly


  int m = 0;
  int z = 0;
  int flow_size = 0;
  int pkt_size = 0; 
  int t = 0;
  int size; int size_r; int random_index; int random_index_r;

   //char buf[MAX_CHARS_PER_LINE];
  while ( routingin.getline(buf, MAX_CHARS_PER_LINE))  //!routingin.eof())
  {
   
    
    int n = 0; 
    
    
    char* token1[MAX_TOKENS_PER_LINE] = {}; 
    
    
    token1[0] = strtok(buf, DELIMITER2);
	#ifdef debug
		 cout << "Token1 " << token1[n] << endl; 
	#endif	
    if (token1[0]) 
    {
      for (n = 1; n < MAX_TOKENS_PER_LINE; n++)
      {
        token1[n] = strtok(0, DELIMITER2);
		if(token1[n])	
		{
			#ifdef debug
				cout << "Token1 " << token1[n] << endl; 		
			#endif
        }
		if (!token1[n]) { 
		#ifdef debug
			cout << "Breaking from the loop " << endl; 
		#endif
		break;} 
      }
    }

  #ifdef debug 
	cout << "The loop iterator value: " << n << endl; 
  #endif
  // For each pair of racks
  vector< vector<string> > set_forward_paths;
  vector< vector<string> > set_reverse_paths;
  
  // Here the token contains one entire route 
  char* token[MAX_TOKENS_PER_LINE] = {};
     for (i = 0; i < n; i++) 
     {

		token[0] = strtok(token1[i], DELIMITER);
		#ifdef debug 
			cout << "Token is : " << token[0] << endl;
		#endif
   		if (token[0])
    	{
      		for (t = 1; t < MAX_TOKENS_PER_LINE; t++)
     		{
        		token[t] = strtok(0, DELIMITER);
				if (token[t])
				{
					#ifdef debug 
						cout << "Token is : " << token[t] << endl;
					#endif
        		}
					if (!token[t]) break;
      		}
    	}

		#ifdef debug 
			cout << "Outside the for loop " << endl;	
		#endif
  		vector<string> forward_path;	// Contains the queues in the forward path
  		vector<string> reverse_path;	//Contains the queues in the reverse path
		for (int j = 1; j < (t-2); j++) 
		{ 
			node1 = token[j];
			node2 = token[j+1];

			#ifdef debug 
				cout << "Inside the next for loop : " << endl;	
			#endif 
			queuename = node1 + "out" + node2;
			queuename1 =  node2 + "out" + node1;
			#ifdef debug 
				cout <<"Here" << queuename << " " << queuename1 << endl;
			#endif
			if (myvars.find(queuename) == myvars.end())
			{
				#ifdef debug 
					cout << "Problem Queue" << queuename << "doesnt exist \n";
				#endif
			}
			else
				//routeout->push_back(myvars[queuename]);
				forward_path.push_back(queuename);

			if (myvars.find(queuename1) == myvars.end())
			{
				#ifdef debug 
				cout << "Problem Queue" << queuename1 << "doesnt exist \n";
				#endif
			}
			else
				//routein->push_back(myvars[queuename1]);
				reverse_path.push_back(queuename1);

    	}
		set_forward_paths.push_back(forward_path);
		set_reverse_paths.push_back(reverse_path);
	}

	//cout << " end of loop " << endl;
	node1 = token[1];
	node2 = token[t-2];
	#ifdef debug 
	cout << "node1 " << node1 << "node2 " << node2 << endl;
	#endif

	
    	// Create new src and sink objects for each route 
	/*
    	tcpSrc = new TcpSrc(NULL,NULL,eventlist); 
    	tcpSnk = new TcpSink(); 
    	tcpRtxScanner.registerTcp(*tcpSrc);
   	routeout = new route_t();
    	routein = new route_t();

	routeout->push_back(&pipe1);
	routein->push_back(&pipe1); 
        routeout->push_back(tcpSnk);
        routein->push_back(tcpSrc);

	flowlabel = "TCP" + ntoa(m) + node1 + node2;
       	flow_size = 1000 + 1000*(rand() % (int)(1000));
	extrastarttime = drand()*100;
        tcpSrc->connect(*routeout,*routein,*tcpSnk,timeFromMs(extrastarttime),flow_size,flowlabel, 1000);
	m++;

	*/

	
	// Reference one forward path and one reverse path randomly from the list of vector
	// First find the vector size which is equal to number of paths between the two pair of nodes
	size = set_forward_paths.size();
	size_r = set_reverse_paths.size();
	int y = 0;
	for (z=0; z < (sim_time); z++)
	{
		// Randomly pick a forward path and then a reverse path index
		random_index = rand() % (int)(size);
		random_index_r = rand() % (int)(size_r);	
		

		//cout << " The random index is " << random_index << " The reverse random index is : " << random_index_r << endl;	
		tcpSrc = new TcpSrc(NULL,NULL,eventlist);
    		tcpSnk = new TcpSink();
    		tcpRtxScanner.registerTcp(*tcpSrc);
   		routeout = new route_t();
    		routein = new route_t();
	
		//cout << "CAME HERE LENGTH = " << forward_path.size() << endl;
		//getchar();
		
		for(y=0; y < set_forward_paths.at(random_index).size(); y++)
		{
			//cout << " Queue name: " << forward_path[y] << endl;	
  			//Pipe pipe2(RTT2, eventlist); pipe2.setName("pipe2");  
  			//Pipe pipe3(RTT2, eventlist); pipe2.setName("pipe3");  
			if (myvars.find(set_forward_paths.at(random_index)[y])  == myvars.end()) 
			{	
				#ifdef debug 
				cout <<"FATAL ERROR FWD " << set_forward_paths.at(random_index)[y] << endl;
				#endif
				assert(false);
			}
	
			routeout->push_back(myvars[set_forward_paths.at(random_index)[y]]); routeout->push_back(&pipe1);

		}


		
		for(y=0; y < set_forward_paths.at(random_index).size(); y++)
		{
			//cout << " Queue name: " << forward_path[y] << endl;	
  			//Pipe pipe2(RTT2, eventlist); pipe2.setName("pipe2");  
  			//Pipe pipe3(RTT2, eventlist); pipe2.setName("pipe3");  
			if (myvars.find(set_reverse_paths.at(random_index_r)[y])  == myvars.end()) 
			{	
				#ifdef debug 
				cout <<"FATAL ERROR REV " << set_reverse_paths.at(random_index_r)[y] << endl;
				#endif 
				assert(false);
			}
			routein->push_back(myvars[set_reverse_paths.at(random_index_r)[y]]); routein->push_back(&pipe1);

		}





		// Push the reverse path elements
		// So we add a separate for loop here

		//routeout->push_back(&pipe1);
		//routein->push_back(&pipe1);

        routeout->push_back(tcpSnk);
        routein->push_back(tcpSrc);
		flowlabel = "TCP" + itoa(m) + node1 + node2;
		flow_size = 8000 + 1000*(rand() % (int)(4));
        extrastarttime = z*1000 +  drand()*100;
        tcpSrc->connect(*routeout,*routein,*tcpSnk,timeFromMs(extrastarttime),10000,flowlabel, 1000);
		m++;



	}

	// If hotspot enabled
	if (!strcmp(argv[3],"hotspot"))
	{

		
		// Randomly pick a forward path and then a reverse path index
		random_index = rand() % (int)(size);
		random_index_r = rand() % (int)(size_r);	
		// Create hotspot
		random_toss = drand();
		if (random_toss > 0.92)
		{
			
			tcpSrc = new TcpSrc(NULL,NULL,eventlist);
            		tcpSnk = new TcpSink();
            		tcpRtxScanner.registerTcp(*tcpSrc);
						
   			routeout = new route_t();
    			routein = new route_t();
	
			for(y=0; y < set_forward_paths.at(random_index).size(); y++)
			{
		
				routeout->push_back(myvars[set_forward_paths.at(random_index)[y]]); routeout->push_back(&pipe1);

			}


			
			for(y=0; y < set_reverse_paths.at(random_index_r).size(); y++)
			{
		
				routein->push_back(myvars[set_reverse_paths.at(random_index_r)[y]]); routein->push_back(&pipe1);

              		} 
			 
        		routeout->push_back(tcpSnk);
        		routein->push_back(tcpSrc);
			flowlabel = "TCP" + itoa(m) + node1 + node2;
			flow_size = 9000000 + 1000000*(rand() % (int)(15));
                	extrastarttime = drand()*100;
				// Flow size between 9MB---24MB flow size
                	tcpSrc->connect(*routeout,*routein,*tcpSnk,timeFromMs(extrastarttime),32000000,flowlabel, 1000);
                	m++;
			
		
		}

	}
  }


	// GO!
	while (eventlist.doNextEvent()) {}
	}

string ntoa(double n) {
	stringstream s;
	s << n;
	return s.str();
	}
string itoa(uint64_t n) {
	stringstream s;
	s << n;
	return s.str();
	}
