#include "exoqueue.h"
#include <math.h>

ExoQueue::ExoQueue(double loss_rate)
  : _loss_rate(loss_rate){
}

void
ExoQueue::receivePacket(Packet& pkt) 
{
  if (drand()<_loss_rate){
    pkt.free();
    return;
  }
  
  pkt.sendOn();
}
