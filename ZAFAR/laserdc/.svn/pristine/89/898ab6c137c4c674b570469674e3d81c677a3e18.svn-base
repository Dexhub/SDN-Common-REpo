#include "config.h" 
#include <sstream> 
#include <string.h> 
#include <strstream> 
#include <iostream> 
#include <math.h> 
#include "network.h" 
#include "randomqueue.h" 
#include "pipe.h" 
#include "eventlist.h" 
#include "logfile.h" 
#include "loggers.h" 
#include "clock.h" 
#include "mtcp.h" 
#include "exoqueue.h" 

simtime_picosec RTT1=timeFromMs(2); 
simtime_picosec RTT2=timeFromMs(500); 


linkspeed_bps SERVICE1 = speedFromMbps(100.0); 


// THE BDP for this path is 12.5 pkts: (100*(10^6)/(1000^8)) * 1/1000
#define FEEDER_BUFFER 25 



void exit_error(char* progr){ 

  cout << "Usage " << progr << " [UNCOUPLED(DEFAULT)|COUPLED_INC|FULLY_COUPLED]" << endl;

  exit(1);

} 
 

int main(int argc, char **argv) { 

  EventList eventlist; 

  eventlist.setEndtime(timeFromSec(60));

  Clock c(timeFromSec(50/100.), eventlist);


  srand(time(NULL)); 


  stringstream filename(ios_base::out); 

  filename << "../data/logout.dat"; 

  cout << "Outputting to " << filename.str() << endl; 

  Logfile logfile(filename.str(),eventlist);

  
  logfile.setStartTime(timeFromSec(0.5));

  
  //TrafficLoggerSimple logger;
  //logfile.addLogger(logger);
  //SinkLoggerSampling sinkLogger = SinkLoggerSampling(timeFromMs(1000),eventlist); 


  //logfile.addLogger(sinkLogger);


  TcpLoggerSimple logTcp;logfile.addLogger(logTcp);
  Pipe pipe1(RTT1, eventlist); pipe1.setName("pipe1"); logfile.writeName(pipe1); 
  Queue S1outS2(SERVICE1, memFromPkt(FEEDER_BUFFER), eventlist,NULL); 
  Queue S2outS1(SERVICE1, memFromPkt(FEEDER_BUFFER), eventlist,NULL); 

  TcpRtxTimerScanner tcpRtxScanner(timeFromMs(10), eventlist); 
   TcpSrc* tcpSrc; 
  TcpSink* tcpSnk; 
  route_t* routeout; 
  route_t* routein; 
  double extrastarttime; 
  //Creating sources and sinks for each flow now 
 
  tcpSrc = new TcpSrc(&logTcp,NULL,eventlist); tcpSrc->setName("Tcp0-S2-S1"); logfile.writeName(*tcpSrc); 
  tcpSnk = new TcpSink();
  //sinkLogger.monitorSink(tcpSnk);
  tcpRtxScanner.registerTcp(*tcpSrc); 
  routeout = new route_t(); 
  routein  = new route_t(); 
  extrastarttime = 50*drand(); 
  // routes for each flow now 
 
  routeout->push_back(&S1outS2); routein->push_back(&S2outS1);   routeout->push_back(&pipe1); 
  routein->push_back(&pipe1); 
  routeout->push_back(tcpSnk); 
  routein->push_back(tcpSrc); 
  tcpSrc->connect(*routeout,*routein,*tcpSnk,timeFromMs(1000)); 
  
/*
  tcpSrc = new TcpSrc(&logTcp,NULL,eventlist); tcpSrc->setName("Tcp1-S1-S2"); logfile.writeName(*tcpSrc); 
  tcpSnk = new TcpSink(); 
  tcpRtxScanner.registerTcp(*tcpSrc); 
  routeout = new route_t(); 
  routein  = new route_t(); 
  extrastarttime = 50*drand(); 
  // routes for each flow now 
 
  routeout->push_back(&S2outS1); routein->push_back(&S1outS2);   routeout->push_back(&pipe1); 
  routein->push_back(&pipe1); 
  routeout->push_back(tcpSnk); 
  routein->push_back(tcpSrc); 
  tcpSrc->connect(*routeout,*routein,*tcpSnk,timeFromMs(extrastarttime)); */
 	while (eventlist.doNextEvent()) {}
} 
