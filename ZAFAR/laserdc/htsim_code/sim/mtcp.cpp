#include "mtcp.h"
#include <math.h>
#include <iostream>
////////////////////////////////////////////////////////////////
//  Multipath TCP SOURCE
////////////////////////////////////////////////////////////////

#define ABS(x) ((x)>=0?(x):-(x))
#define A_SCALE 500

MultipathTcpSrc::MultipathTcpSrc(char cc_type,EventList& ev,MultipathTcpLogger* logger):
  EventSource(ev,"MTCP"),_logger(logger)
{
	_highest_sent = 0;
	_last_acked = 0;
	_cc_type = cc_type;
	a = A_SCALE;
}

void MultipathTcpSrc::addSubflow(TcpSrc* subflow){
  _subflows.push_back(subflow);
  subflow->joinMultipathConnection(this);
}

void
MultipathTcpSrc::receivePacket(Packet& pkt) {
}

uint32_t
MultipathTcpSrc::inflate_window(uint32_t cwnd, int newly_acked,uint32_t mss) {
  int tcp_inc = (newly_acked * mss)/cwnd;
  int tt = (newly_acked * mss) % cwnd;
  int tmp, total_cwnd, tmp2;

  if (tcp_inc==0)
    return cwnd;

  switch(_cc_type){

  case UNCOUPLED:
    return cwnd + tcp_inc;

  case FULLY_COUPLED:
    total_cwnd = compute_total_window();
    tt = (int)(newly_acked * mss * A);
    tmp = tt/total_cwnd;

    if ((rand()%total_cwnd) < tt % total_cwnd)
      tmp ++;

    return cwnd + tmp;

  case COUPLED_INC:
    total_cwnd = compute_total_window();
    tmp2 = (newly_acked * mss * a) / total_cwnd;

    tmp = tmp2 / A_SCALE;


    if (tmp < 0){
      printf("Negative increase!");
      tmp = 0;
    }

    if (rand() % A_SCALE < tmp2 % A_SCALE)
      tmp++;
    
    if (tmp>tcp_inc)//capping
      tmp = tcp_inc;

    if ((cwnd + tmp)/mss != cwnd/mss){
      a = compute_a_scaled();
      if (_logger){
	_logger->logMultipathTcp(*this,MultipathTcpLogger::WINDOW_UPDATE);
	_logger->logMultipathTcp(*this,MultipathTcpLogger::RTT_UPDATE);
	_logger->logMultipathTcp(*this,MultipathTcpLogger::CHANGE_A);
      }
    }

    return cwnd + tmp;

  case COUPLED_TCP:
    tmp2 = (newly_acked * mss * a) / cwnd;

    tmp = tmp2 / A_SCALE;


    if (tmp < 0){
      printf("Negative increase!");
      tmp = 0;
    }

    if (rand() % A_SCALE < tmp2 % A_SCALE)
      tmp++;
    
    if (tmp>tcp_inc)//capping
      tmp = tcp_inc;

    if ((cwnd + tmp)/mss != cwnd/mss){
      a = compute_a_tcp();
      if (_logger){
	_logger->logMultipathTcp(*this,MultipathTcpLogger::WINDOW_UPDATE);
	_logger->logMultipathTcp(*this,MultipathTcpLogger::RTT_UPDATE);
	_logger->logMultipathTcp(*this,MultipathTcpLogger::CHANGE_A);
      }
    }
    return cwnd + tmp;

  default:
    printf("Unknown cc type %d\n",_cc_type);
    exit(1);
  }
}

uint32_t 
MultipathTcpSrc::deflate_window(uint32_t cwnd, uint32_t mss){
  int d;
  switch(_cc_type){
  case UNCOUPLED:
  case COUPLED_INC:
  case COUPLED_TCP:
    return max(cwnd/2,(uint32_t)(2*mss));

  case FULLY_COUPLED:
    d = (int)cwnd - compute_total_window()/B;
    if (d<0) d = 0;

    //cout << "Dropping to " << max(2*mss,(uint32_t)d) << endl;
    return max(2*mss, (uint32_t)d);

  default:
    printf("Unknown cc type %d\n",_cc_type);
    exit(1);    
  }
}

uint32_t
MultipathTcpSrc::compute_total_window(){
  list<TcpSrc*>::iterator it;
  TcpSrc* crt;
  uint32_t crt_wnd = 0;

  /*  if (_subflows.size()!=2){
    printf("Expecting 2 subflows, found %d\n",_subflows.size());
    exit(1);
    }*/

  //  printf ("Tot wnd ");
  for (it = _subflows.begin();it!=_subflows.end();it++){
    crt = *it;

    if (crt->_in_fast_recovery)
      crt_wnd += crt->_ssthresh;
    else
      crt_wnd += crt->_cwnd;
  }

  return crt_wnd;
}


uint32_t
MultipathTcpSrc::compute_a_tcp(){
  if (_cc_type!=COUPLED_TCP)
    return 0;

  if (_subflows.size()!=2){
    cout << "Expecting 2 subflows, found" << _subflows.size() << endl;
    exit(1);
  }

  TcpSrc* flow0 = _subflows.front();
  TcpSrc* flow1 = _subflows.back();

  uint32_t cwnd0 = flow0->_in_fast_recovery?flow0->_ssthresh:flow0->_cwnd;
  uint32_t cwnd1 = flow1->_in_fast_recovery?flow1->_ssthresh:flow1->_cwnd;

  double pdelta = (double)cwnd1/cwnd0;
  double rdelta;

#if USE_AVG_RTT
  if (flow0->_rtt_avg>timeFromMs(0)&&flow1->_rtt_avg>timeFromMs(1))
    rdelta = (double)flow0->_rtt_avg / flow1->_rtt_avg;
  else
   rdelta = 1;

#else
  rdelta = (double)flow0->_rtt / flow1->_rtt;

#endif


  if (1 < pdelta * rdelta * rdelta){
#if USE_AVG_RTT
    if (flow0->_rtt_avg>timeFromMs(0)&&flow1->_rtt_avg>timeFromMs(1))
      rdelta = (double)flow1->_rtt_avg / flow0->_rtt_avg;
    else
      rdelta = 1;
#else
    rdelta = (double)flow1->_rtt / flow0->_rtt;
#endif

    pdelta = (double)cwnd0/cwnd1;
  }

  double t = 1.0+rdelta*sqrt(pdelta); 

  return (uint32_t)(A_SCALE/t/t);
}


uint32_t MultipathTcpSrc::compute_a_scaled(){
  if (_cc_type!=COUPLED_INC && _cc_type!=COUPLED_TCP)
    return 0;

  if (_subflows.size()!=2){
    cout << "Expecting 2 subflows, found" << _subflows.size() << endl;
    exit(1);
  }
    
  TcpSrc* flow0 = _subflows.front();
  TcpSrc* flow1 = _subflows.back();

  uint32_t cwnd0 = flow0->_in_fast_recovery?flow0->_ssthresh:flow0->_cwnd;
  uint32_t cwnd1 = flow1->_in_fast_recovery?flow1->_ssthresh:flow1->_cwnd;

  uint32_t rtt0 = timeAsMs(flow0->_rtt);
  uint32_t rtt1 = timeAsMs(flow1->_rtt);

  if (rtt0==0 || rtt1 == 0)
    {
      rtt0 = 1;
      rtt1 = 1;
    }

  uint64_t t0 = (uint64_t)cwnd0 * flow0->_mss * flow0->_mss / rtt0 / rtt0;
  uint64_t t1 = (uint64_t)cwnd1 * flow1->_mss * flow1->_mss / rtt1 / rtt1;

  uint32_t sum_denominator = cwnd0 * flow0->_mss / rtt0 + cwnd1 * flow1->_mss / rtt1;

  return (uint32_t)( A_SCALE * (uint64_t)(cwnd0 + cwnd1) * max (t0,t1) / sum_denominator / sum_denominator);
}

double
MultipathTcpSrc::compute_a(){
  if (_cc_type!=COUPLED_INC && _cc_type!=COUPLED_TCP)
    return -1;

  if (_subflows.size()!=2){
    cout << "Expecting 2 subflows, found" << _subflows.size() << endl;
    exit(1);
  }

  double a;
    
  TcpSrc* flow0 = _subflows.front();
  TcpSrc* flow1 = _subflows.back();

  uint32_t cwnd0 = flow0->_in_fast_recovery?flow0->_ssthresh:flow0->_cwnd;
  uint32_t cwnd1 = flow1->_in_fast_recovery?flow1->_ssthresh:flow1->_cwnd;

  double pdelta = (double)cwnd1/cwnd0;
  double rdelta;

#if USE_AVG_RTT
  if (flow0->_rtt_avg>timeFromMs(0)&&flow1->_rtt_avg>timeFromMs(1))
    rdelta = (double)flow0->_rtt_avg / flow1->_rtt_avg;
  else
   rdelta = 1;

  //cout << "R1 " << flow0->_rtt_avg/1000000000 << " R2 " << flow1->_rtt_avg/1000000000 << endl;
#else
  rdelta = (double)flow0->_rtt / flow1->_rtt;

  //cout << "R1 " << flow0->_rtt/1000000000 << " R2 " << flow1->_rtt/1000000000 << endl;
#endif


  //cout << "R1 " << flow0->_rtt_avg/1000000000 << " R2 " << flow1->_rtt_avg/1000000000 << endl;

  //second_better
  if (1 < pdelta * rdelta * rdelta){
#if USE_AVG_RTT
    if (flow0->_rtt_avg>timeFromMs(0)&&flow1->_rtt_avg>timeFromMs(1))
      rdelta = (double)flow1->_rtt_avg / flow0->_rtt_avg;
    else
      rdelta = 1;
#else
    rdelta = (double)flow1->_rtt / flow0->_rtt;
#endif

    pdelta = (double)cwnd0/cwnd1;
  }

  if (_cc_type==COUPLED_INC){
    a = (1+pdelta)/(1+pdelta*rdelta)/(1+pdelta*rdelta);
    //cout << "A\t" << a << endl;


    if (a<0.5){
      cout << " a comp error " << a << ";resetting to 0.5" <<endl;
      a = 0.5;
    }

    //a = compute_a2();
    ///if (ABS(a-compute_a2())>0.01)
    //cout << "Compute a error! " <<a << " vs " << compute_a2()<<endl;
  }
  else{
    double t = 1.0+rdelta*sqrt(pdelta); 
    a = 1.0/t/t;
  }

  return a;
}

void MultipathTcpSrc::doNextEvent(){}


////////////////////////////////////////////////////////////////
//  MTCP SINK
////////////////////////////////////////////////////////////////

MultipathTcpSink::MultipathTcpSink() 
{}

void MultipathTcpSink::addSubflow(TcpSink* sink){
  _subflows.push_back(sink);
  sink->joinMultipathConnection(this);
}

void
MultipathTcpSink::receivePacket(Packet& pkt) {
	}	

