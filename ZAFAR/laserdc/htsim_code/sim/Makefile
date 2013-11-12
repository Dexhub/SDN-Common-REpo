OBJS = eventlist.o main.o tcppacket.o pipe.o queue.o tcp.o mtcp.o \
       loggers.o logfile.o clock.o cleanup_clock.o config.o network.o qcn.o exoqueue.o randomqueue.o 
CC = g++
CFLAGS = -DNOMINMAX -Wall -g -pg 
all:	htsim
htsim:	$(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o htsim

clean:	
	rm *.o htsim
config.o:	config.cpp config.h
eventlist.o:    eventlist.cpp eventlist.h config.h
main.o:		main.cpp tcp.h loggers.h network.h config.h
queue.o:	queue.cpp queue.h pipe.h tcppacket.h loggers.h network.h \
		loggertypes.h eventlist.h config.h
exoqueue.o:	exoqueue.cpp exoqueue.h network.h 
pipe.o:		pipe.cpp pipe.h tcppacket.h loggers.h config.h
network.o:	network.cpp network.h loggertypes.h config.h
tcp.o:		tcp.cpp tcp.h tcppacket.h network.h eventlist.h loggers.h \
		config.h
mtcp.o:		mtcp.cpp mtcp.h tcppacket.h network.h eventlist.h loggers.h \
		config.h
tcppacket.o:	tcppacket.cpp tcppacket.h config.h
loggers.o:	loggers.cpp loggers.h loggertypes.h network.h eventlist.h \
		queue.h tcp.h config.h
logfile.o:	logfile.cpp loggers.h logfile.h loggertypes.h network.h \
		eventlist.h config.h
clock.o:	clock.cpp clock.h eventlist.h config.h

qcn.o: qcn.cpp qcn.h loggers.h config.h 

.cpp.o:
	source='$<' object='$@' libtool=no \
        depfile='$(DEPDIR)/$*.Po' tmpdepfile='$(DEPDIR)/$*.TPo' \
        $(CXXDEPMODE) $(depcomp) \
        $(CC) $(CFLAGS) -Wuninitialized  -c -o $@ `test -f $< || echo '$(srcdir)/'`$<
