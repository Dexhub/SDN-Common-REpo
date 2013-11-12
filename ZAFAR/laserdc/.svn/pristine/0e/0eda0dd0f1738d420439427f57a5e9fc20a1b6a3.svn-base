#ifndef TCP_H
#define TCP_H

#include <set>

/*

 * A TCP source and sink
 */

#include <list>
#include "config.h"
#include "network.h"
#include "tcppacket.h"
#include "eventlist.h"
#include <queue>

//Vyas
#define BUFFERDELTIME 200000000000

class TcpSink;
class MultipathTcpSrc;
class MultipathTcpSink;

class TcpSrc : public PacketSink, public EventSource {
friend class TcpSink;
public:
	TcpSrc(TcpLogger* logger, TrafficLogger* pktlogger, EventList &eventlist);
	~TcpSrc(); // Vyas
	void connect(route_t& routeout, route_t& routeback, TcpSink& sink, simtime_picosec startTime, uint64_t flow_size, string flowlabel, uint16_t pktsize);
	void startflow();
	inline void joinMultipathConnection(MultipathTcpSrc* multipathSrc){
	  _mSrc = multipathSrc;
	};
	void doNextEvent() {startflow();}
	void receivePacket(Packet& pkt);
	void rtx_timer_hook(simtime_picosec now);
// should really be private, but loggers want to see:
	uint64_t _highest_sent;  //seqno is in bytes
	uint32_t _cwnd;
	uint32_t _maxcwnd;
	uint64_t _last_acked;
	uint32_t _ssthresh;
	uint16_t _dupacks;
	// Added by zafar
	uint64_t _flow_size;
	uint64_t _start_time;
	string _flow_label;
	bool complete;
	// Vyas
	uint64_t deletion_time;

	//round trip time estimate, needed for coupled congestion control
	simtime_picosec _rtt, _rto, _mdev;
	simtime_picosec _rtt_avg, _rtt_cum;
	int _sawtooth;

	uint16_t _mss;
	uint32_t _unacked; // an estimate of the amount of unacked data WE WANT TO HAVE in the network
	uint32_t _effcwnd; // an estimate of our current transmission rate, expressed as a cwnd
	uint64_t _recoverq;
	bool _in_fast_recovery;
private:
	// Housekeeping
	TcpLogger* _logger;
	TrafficLogger* _pktlogger;
	// Connectivity
	PacketFlow _flow;
	TcpSink* _sink;
	route_t* _route;
	MultipathTcpSrc* _mSrc;

	// Mechanism
	void inflate_window();
	void send_packets();
	void retransmit_packet();
	simtime_picosec _last_sent_time;
	};

class TcpSink : public PacketSink, public Logged {
friend class TcpSrc;
public:
        TcpSink();
        ~TcpSink();
	void receivePacket(Packet& pkt);
	inline void joinMultipathConnection(MultipathTcpSink* sink){
	  _mSink = sink;
	};
	TcpAck::seq_t _cumulative_ack; // the packet we have cumulatively acked

private:
	// Connectivity
	void connect(TcpSrc& src, route_t& route);
	route_t* _route;
	TcpSrc* _src;
	MultipathTcpSink* _mSink;
	// Mechanism
	void send_ack(simtime_picosec ts);

	list<TcpAck::seq_t> _received; // list of packets above a hole, that we've received
};

class TcpRtxTimerScanner : public EventSource {
public:
    TcpRtxTimerScanner(simtime_picosec scanPeriod, EventList& eventlist);
    void doNextEvent();
    void registerTcp(TcpSrc &tcpsrc);
 	void remove (TcpSrc* t);
	
private:
		simtime_picosec _scanPeriod;
		typedef set<TcpSrc*> tcps_t;
 	    	tcps_t _tcps;
		
};

//Vyas
class TcpTmp
{
	public:
		TcpSrc* tcpsrc;
		TcpSink* tcpsink;
		uint64_t deletion_time;
		TcpTmp(TcpSrc* s, TcpSink* k, uint64_t ti)
		{
			tcpsrc = s;	
			tcpsink = k;
			deletion_time = ti;	
		}

};


//Vyas
class CompareTcpSrc{
public:
    bool operator()(TcpTmp &t1, TcpTmp &t2)
    {
       if ( (t2.deletion_time) < (t1.deletion_time)) return true;
       return false;
    }
};


#endif
