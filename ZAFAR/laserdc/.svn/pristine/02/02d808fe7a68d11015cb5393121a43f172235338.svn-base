
#include "mtcp.h"
#include "config.h"
#include <iostream>



// Vyas
bool notdeleted(string flowlabel);
extern priority_queue<TcpTmp,vector<TcpTmp>,CompareTcpSrc> TcpSrcesToDelete; 
extern set<string> deletedflows;


////////////////////////////////////////////////////////////////
//  TCP SOURCE
////////////////////////////////////////////////////////////////
//Vyas: add placeholder destructors
TcpSrc::~TcpSrc()
{

}
TcpSink::~TcpSink()
{

}

TcpSrc::TcpSrc(TcpLogger* logger, TrafficLogger* pktlogger, 
	       EventList &eventlist)
: EventSource(eventlist,"tcp"),  _logger(logger), _flow(pktlogger)
{

	//cout << "Calling constructor \n";
	_maxcwnd = 2000000;
	_sawtooth = 0;
	_rtt_avg = timeFromMs(0);
	_rtt_cum = timeFromMs(0);
	_highest_sent = 0;
	_effcwnd = 0;
	_ssthresh = 0xffffffff;
	_last_acked = 0;
	_dupacks = 0;
	_rtt = 0;
	_rto = timeFromMs(1);
	_mdev = 0;
	_mss = TcpPacket::DEFAULTDATASIZE;
	_recoverq = 0;
	_in_fast_recovery = false;
	_mSrc = NULL;
	// Added by zafar
	_flow_size = 0;
	_start_time = 0;
	_flow_label = "";
	complete = false;
}

void 
TcpSrc::startflow() {
	_cwnd = _mss;
	_unacked = _cwnd;
	// Added by zafar
	_start_time = eventlist().now();
	double completion_time_msec = timeAsMs(_start_time);

	cout << " ST: " << completion_time_msec << " ID: " << _flow_label << " SIZE " << _flow_size << endl; 	
	send_packets();
	}

void 
TcpSrc::connect(route_t& routeout, route_t& routeback, TcpSink& sink, simtime_picosec starttime, uint64_t flow_size, string flowlabel, uint16_t pktsize) 
	{
	_route = &routeout;
	_sink = &sink;
	_flow.id = id; // identify the packet flow with the TCP source that generated it
	// Added by zafar: flow size for each flow
	_flow_size = flow_size;
	_flow_label = flowlabel;
	_mss = pktsize;

	_sink->connect(*this, routeback);
	eventlist().sourceIsPending(*this,starttime);
	}


void
TcpSrc::receivePacket(Packet& pkt) 
{
  simtime_picosec ts;
  TcpAck *p = (TcpAck*)(&pkt);
  TcpAck::seq_t seqno = p->ackno();
  pkt.flow().logTraffic(pkt,*this,TrafficLogger::PKT_RCVDESTROY);
  
  ts = p->ts();
  p->free();

  #ifdef debug	
  cout << " Flowlabel = " << _flow_label << " Ack Seqno "<< seqno  << " _mss " << _mss << " flowsize = " <<  _flow_size << endl;
  #endif
  // Added by zafar: check whether the flow size has been met
  if (((seqno) >= _flow_size) && (complete == false))
  {
	//cout << "FLOW SIZE: " << seqno + _mss << " FLOW ID: " << _flow_label <<  "\n"; 
	uint64_t time = eventlist().now() - _start_time;
	double completion_time_msec = timeAsMs(time);
	cout << " CT: " << completion_time_msec << " ID: " << _flow_label << endl;
	complete = true;
	// Vyas: scheduled deletion time .. give some buffer 
	deletion_time = time + BUFFERDELTIME;
	//Vyas
	cout << " Scheduling flowId " << _flow_label << " for deletion at " << timeAsMs(deletion_time) << endl;
	TcpTmp todel(this,_sink,deletion_time);
	TcpSrcesToDelete.push(todel);
	deletedflows.insert(_flow_label);
	return; 	 	
  }
	
  if ( ((seqno) < _flow_size) && (complete == false))
  {

  assert(seqno >= _last_acked);  // no dups or reordering allowed in this simple simulator
  /*
  cout << seqno + _mss << "FLOW SIZE \n"; 
  uint64_t time = eventlist().now() - _start_time;
  double completion_time_msec = timeAsMs(time);
  cout << " TIME ELAPSED: " << completion_time_msec << " FLOW ID" << _flow.id << "\n"; 	*/



  //compute rtt
  int64_t m = eventlist().now()-ts;
  //cout << "RTT " << m / 1000000 << endl;
  if (m!=0){
    //m >>= 3;
      
    if (_rtt>0){
      m -= (_rtt>>3);
      _rtt += m;
      
      if (m<0)
	  m = -m;
      
      m -= _mdev>>2;
      _mdev += m;
    }
    else {
	_rtt = m<<3;
	_mdev = m<<2;
    }
  }

  _rto = (_rtt >> 3) + _mdev;
  
  if (_rto>timeFromMs(5000)){
    //cout << "Large RTO! " << _rto/1000000000 << " rtt " << _rtt / 8000000000.0 << " mdev" << _mdev / 1000000000 << endl;
    _rto = timeFromMs(2000);
    //_rto = 2 * (_rtt>>3);//timeFromMs(5000);
  }

	if (seqno > _last_acked) { // a brand new ack
		if (!_in_fast_recovery) { // best behaviour: proper ack of a new packet, when we were expecting it
			#ifdef debug
			cout << " In the condition seqno > last_acked and ! fast_recovery " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl;
			#endif 
			_last_acked = seqno;
			_dupacks = 0;
			inflate_window();
			_unacked = _cwnd;
			_effcwnd = _cwnd;
			if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV);
			send_packets();
			return;
			}
		// We're in fast recovery, i.e. one packet has been
		// dropped but we're pretending it's not serious
		if (seqno >= _recoverq) {
			#ifdef debug
			 cout << " In the condition seqno > last_acked and seqno >= _recoverq " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl; 
			#endif   
		
		 // got ACKs for all the "recovery window": resume
		    // normal service
			uint32_t flightsize = _highest_sent - seqno;
			_cwnd = min(_ssthresh, flightsize + _mss);
			_unacked = _cwnd;
			_effcwnd = _cwnd;
			_last_acked = seqno;
			_dupacks = 0;
			_in_fast_recovery = false;
			if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_FR_END);
			send_packets();
			return;
			}
		// In fast recovery, and still getting ACKs for the
		// "recovery window"
		// This is dangerous. It means that several packets
		// got lost, not just the one that triggered FR.
		uint32_t new_data = seqno - _last_acked;
		_last_acked = seqno;
		if (new_data < _cwnd) _cwnd -= new_data; else _cwnd=0;
		_cwnd += _mss;
		if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_FR);
		retransmit_packet(); 
		send_packets();
		return;
		}
	// It's a dup ack
	if (_in_fast_recovery) { // still in fast recovery; hopefully the prodigal ACK is on it's way
		#ifdef debug
		cout << " In fast recovery " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl;
		#endif
		_cwnd += _mss;
		if (_cwnd>_maxcwnd) _cwnd = _maxcwnd;
		// When we restart, the window will be set to
		// min(_ssthresh, flightsize+_mss), so keep track of
		// this
		_unacked = min(_ssthresh, (uint32_t)(_highest_sent-_recoverq+_mss)); 
		if (_last_acked+_cwnd >= _highest_sent+_mss) _effcwnd=_unacked; // starting to send packets again
		if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_DUP_FR);
		send_packets();
		return;
		}
	// Not yet in fast recovery. What should we do instead?
	_dupacks++;
if (_dupacks <= 3) { // not yet serious worry
		#ifdef debug
		cout << " _dupacks!=3 " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl;
		#endif
		if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_DUP);
		send_packets();
		return;
		}
	// _dupacks==3
	if (_last_acked < _recoverq) {  //See RFC 3782: if we haven't
					//recovered from timeouts
					//etc. don't do fast recovery
		#ifdef debug
		cout << " _last_acked < _recoverq " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl;
		#endif
		if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_3DUPNOFR);
		return;
		}

	// begin fast recovery
	#ifdef debug
	cout << " begin fast recovery < _recoverq " << " Seqno: " << seqno << " _last_acked: " << _last_acked << " FLOW ID : " << _flow_label << endl;
	#endif
	if (_mSrc==NULL)
	  _ssthresh = max(_cwnd/2, (uint32_t)(2 * _mss));
	else
	  _ssthresh = _mSrc->deflate_window(_cwnd,_mss);

	if (_sawtooth>0)
	  _rtt_avg = _rtt_cum/_sawtooth;
	else
	  _rtt_avg = timeFromMs(0);
	_sawtooth = 0;
	_rtt_cum = timeFromMs(0);


	retransmit_packet();
	_cwnd = _ssthresh + 3 * _mss;
	_unacked = _ssthresh;
	_effcwnd = 0;
	_in_fast_recovery = true;
	_recoverq = _highest_sent; // _recoverq is the value of the
				   // first ACK that tells us things
				   // are back on track
	if (_logger) _logger->logTcp(*this, TcpLogger::TCP_RCV_DUP_FASTXMIT);
	}
}

void
TcpSrc::inflate_window() {
	int newly_acked = (_last_acked + _cwnd) - _highest_sent;
	// be very conservative - possibly not the best we can do, but
	// the alternative has bad side effects.
	if (newly_acked > _mss) newly_acked = _mss; 
	if (newly_acked < 0)
		return;
	if (_cwnd < _ssthresh) { //slow start
		int increase = min(_ssthresh - _cwnd, (uint32_t)newly_acked);
		_cwnd += increase;
		newly_acked -= increase;
		}
	// additive increase
	else {
	  uint32_t pkts = _cwnd/_mss;

	  if (_mSrc==NULL){
	    //int tt = (newly_acked * _mss) % _cwnd;
	    _cwnd += (newly_acked * _mss) / _cwnd;  //XXX beware large windows, when this increase gets to be very small

	    //if (rand()%_cwnd < tt)
	    //_cwnd++;
	  }
	  else 
	    _cwnd = _mSrc->inflate_window(_cwnd,newly_acked,_mss);

	  if (pkts!=_cwnd/_mss)
	    {
	      _rtt_cum += _rtt;
	      _sawtooth ++;
	    }
	}
}

// Note: the data sequence number is the number of Byte1 of the packet, not the last byte.
void 
TcpSrc::send_packets() {
	double nowtime = eventlist().now();
	double completion_time_msec = timeAsMs(nowtime);
	// Added by zafar: To check that the flow_size has not exceeded
		//	cout << _highest_sent << "Seq no \n";
		if (complete == true)
		{
		
		//	_cwnd = 1;
		//	_maxcwnd = 1;
		#ifdef debug
		cout << "In the send function post complete flow = " << _flow_label << "time = " << completion_time_msec << endl;	
		#endif 

		}
		else 
		{
		 if ( ( (_last_acked + _cwnd) <  (_highest_sent + _mss) ) ){
			#ifdef debug
			cout << "In the send function skipping while flow = " << _flow_label << "time = " << completion_time_msec << endl;	
			#endif
			}
		
		//Vyas: make sure no spurious pkts are sent after completion size is reached..
 		unsigned int tmpcwnd = 0;
		if ( (_last_acked + _cwnd) < _flow_size)
		{
			tmpcwnd = _cwnd;	
		}
		else 
		{
			tmpcwnd = _flow_size - _last_acked;	

		}
		while (( (_last_acked + tmpcwnd) >= (_highest_sent + _mss)) && (complete == false)) 
		{
                //	cout << "In the send function while loop" << " complete = " << complete << " flow = " << _flow_label << endl;
			TcpPacket* p = TcpPacket::newpkt(_flow, *_route, _highest_sent+1, _mss);
			p->flow().logTraffic(*p,*this,TrafficLogger::PKT_CREATESEND);
			p->setflowlabel(_flow_label);

			_highest_sent += _mss;  //XX beware wrapping
			_last_sent_time = eventlist().now();
			p->set_ts(_last_sent_time);
			#ifdef debug
			cout << "In the send function while loop  time= " << completion_time_msec << "_highest_sent: " << _highest_sent << " _cwnd:" << tmpcwnd << " complete = " << complete << " flow = " << _flow_label << endl;
			#endif
			p->sendOn();
			}
		}

}

void 
TcpSrc::retransmit_packet() {

	double nowtime = eventlist().now();
	double completion_time_msec = timeAsMs(nowtime);
	if (complete == true)
	{
		#ifdef debug
		cout << "In the retransmit function  " << "_highest_sent: " << _highest_sent << " _cwnd:" << _cwnd << " complete = " << complete << " flow = " << _flow_label << endl;
		#endif
		return;
	//cout << "In the retransmit function " << endl;
	}
	if (complete == false)
	{
		#ifdef debug
		cout << "In the retransmit function  time=" << completion_time_msec << " _highest_sent: " << _highest_sent << " _cwnd:" << _cwnd << " complete = " << complete << " flow = " << _flow_label << endl;
		#endif
		TcpPacket* p = TcpPacket::newpkt(_flow, *_route, _last_acked+1, _mss);
		p->flow().logTraffic(*p,*this,TrafficLogger::PKT_CREATESEND);
		p->setflowlabel(_flow_label);
		_last_sent_time = eventlist().now();
		p->sendOn();
	}
	}

void
TcpSrc::rtx_timer_hook(simtime_picosec now) {

	// Added by zafar
	if (complete == true) return;
		
	if (_highest_sent == 0) return;

	if (now <= _last_sent_time + _rto) return;
	// RTX timer expired

  // Commented by zafar
	//cout <<"At " << now/(double)1000000000<< " RTO " << _rto/1000000000 << " RTT "<< _rtt/1000000000/8 << endl;
	cout << "Here TCPSrc for flow label " << _flow_label << endl;

	if (_logger) _logger->logTcp(*this, TcpLogger::TCP_TIMEOUT);
	if (_in_fast_recovery) {
		uint32_t flightsize = _highest_sent - _last_acked;
		//uint32_t bytesremain = _flow_size - _highest_sent;
		//uint32_t temp = min(bytesremain,flightsize + _mss); 
		_cwnd = min(_ssthresh,flightsize + _mss);
		}
	if (_mSrc==NULL)
	  _ssthresh = max(_cwnd/2, (uint32_t)(2 * _mss));
	else
	  _ssthresh = _mSrc->deflate_window(_cwnd,_mss);

	if (_sawtooth>0)
	  _rtt_avg = _rtt_cum/_sawtooth;
	else
	  _rtt_avg = timeFromMs(0);
	_sawtooth = 0;
	_rtt_cum = timeFromMs(0);

	_cwnd = _mss;
	_unacked = _cwnd;
	_effcwnd = _cwnd;
	_in_fast_recovery = false;
	_recoverq = _highest_sent;
	// Added by zafar
	_highest_sent = _last_acked + _mss;
	_dupacks = 0;
	retransmit_packet();
	//reset rtx timer
	_last_sent_time = now;
	}
//	}


////////////////////////////////////////////////////////////////
//  TCP SINK
////////////////////////////////////////////////////////////////

TcpSink::TcpSink() 
: Logged("sink")  {}

void 
TcpSink::connect(TcpSrc& src, route_t& route)
	{
	_src = &src;
	_route = &route;
	_cumulative_ack = 0;
	}

// Note: _cumulative_ack is the last byte we've ACKed.
// seqno is the first byte of the new packet.
void
TcpSink::receivePacket(Packet& pkt) {
	TcpPacket *p = (TcpPacket*)(&pkt);
	TcpPacket::seq_t seqno = p->seqno();
	#ifdef debug
	cout << " Receiver seqno: " << seqno << " FLOW: ID " << _src->_flow_label << endl;
	#endif
	simtime_picosec ts = p->ts();
	int size = p->size(); // TODO: the following code assumes all packets are the same size
	pkt.flow().logTraffic(pkt,*this,TrafficLogger::PKT_RCVDESTROY);
	p->free();

	if (seqno == _cumulative_ack+1) { // it's the next expected seq no
	  _cumulative_ack = seqno + size - 1;
	  // are there any additional received packets we can now ack?
	  while (!_received.empty() && (_received.front() == _cumulative_ack+1) ) {
	    _received.pop_front();
	    _cumulative_ack+= size;
	  }
	} 
	else if (seqno < _cumulative_ack+1) {} //must have been a bad retransmit
	else { // it's not the next expected sequence number
	  if (_received.empty()) {
		  _received.push_front(seqno);
	  } 
	  else if (seqno > _received.back()) { // likely case
	    _received.push_back(seqno);
	  } 
	  else { // uncommon case - it fills a hole
	    list<uint64_t>::iterator i;
	    for (i = _received.begin(); i != _received.end(); i++) {
	      if (seqno == *i) break; // it's a bad retransmit
	      if (seqno < (*i)) {
		_received.insert(i, seqno);
		break;
	      }
	    }
	  }
	}
	send_ack(ts);
}	

void 
TcpSink::send_ack(simtime_picosec ts) {
	TcpAck *ack = TcpAck::newpkt(_src->_flow, *_route, 0, _cumulative_ack);
	ack->setflowlabel(_src->_flow_label);
	ack->flow().logTraffic(*ack,*this,TrafficLogger::PKT_CREATESEND);
	ack->set_ts(ts);
	ack->sendOn();
}


////////////////////////////////////////////////////////////////
//  TCP RETRANSMISSION TIMER
////////////////////////////////////////////////////////////////

TcpRtxTimerScanner::TcpRtxTimerScanner(simtime_picosec scanPeriod, EventList& eventlist)
: EventSource(eventlist,"RtxScanner"), 
	_scanPeriod(scanPeriod)
	{
	eventlist.sourceIsPendingRel(*this, _scanPeriod);
	}

void 
TcpRtxTimerScanner::registerTcp(TcpSrc &tcpsrc)
	{
	//Vyas -- do this only for active stuff _tcps.push_back(&tcpsrc);
	_tcps.insert(&tcpsrc);
	}
// Vyas -- add this to avoid RTO for deleted stuff ..
void TcpRtxTimerScanner::remove(TcpSrc* t)
{
	_tcps.erase(t);
} 


void
TcpRtxTimerScanner::doNextEvent() 
	{
	simtime_picosec now = eventlist().now();
	tcps_t::iterator i;
	for (i = _tcps.begin(); i!=_tcps.end(); i++) {
			(*i)->rtx_timer_hook(now);
		}
	eventlist().sourceIsPendingRel(*this, _scanPeriod);
	}
