#include "Timer.h"
#include "RadioCountToLeds.h"
#include <stdio.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

module RadioCountToLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface AMPacket;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked = FALSE;
  uint16_t counter = 0;
  char logbuf[1024];
  time_t timep;
  struct tm *p;

void resetLog()
{
	FILE *fd = fopen("log.txt", "w+");
	if(fd==0)
	{
		printf("Opening Log File Error!\n");
		exit(0);
	}
	fclose(fd);
}

void writeLog(int isrecved, nx_uint16_t send_node, nx_uint16_t shour, nx_uint16_t smin, nx_uint16_t ssec, nx_uint16_t recv_node, nx_uint16_t rhour, nx_uint16_t rmin, nx_uint16_t rsec)
  {
        FILE *fd = fopen("log.txt", "a+");

        if(fd==0)
	{
		printf("Opening Log File Error!\n");
		exit(0);
	}
        memset(logbuf, 0, sizeof(logbuf));

	if(!isrecved)
	{
		sprintf(logbuf, "Send %d %d:%02d:%02d\n", send_node, shour, smin, ssec);
	}
	else
        {
        	sprintf(logbuf, "Recv %d %d:%02d:%02d %d %d:%02d:%02d\n", send_node, shour, smin, ssec, recv_node, rhour, rmin, rsec);
        }
        fprintf(fd, logbuf);

        fclose(fd);

}
  
  event void Boot.booted() {
    call Leds.led0On();
    dbg("Boot", "Application booted.\n");
    resetLog();
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(250);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    int hour, min, sec;
    counter++;

    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return;
      }

      rcm->counter = counter;
      rcm->src = call AMPacket.source(&packet);
      time(&timep);
      p = gmtime(&timep);
      hour = p->tm_hour;
      min = p->tm_min;
      sec = p->tm_sec;
      rcm->hour = htons(hour);
      rcm->min = htons(min);
      rcm->sec = htons(sec);
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
        writeLog(0, rcm->src, hour, min, sec, 0, 0, 0, 0);
	dbg("RadioCountToLedsC", "RadioCountToLedsC: %d:%02d:%02d packet %d is sent from Node %d.\n", hour, min, sec, counter, rcm->src);	
	locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    int cur_hour, cur_min, cur_sec, shour, smin, ssec;
    
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;

      shour = ntohs(rcm->hour);
      smin = ntohs(rcm->min);
      ssec = ntohs(rcm->sec);
      time(&timep);
      p = gmtime(&timep);
      cur_hour = p->tm_hour;
      cur_min = p->tm_min;
      cur_sec = p->tm_sec;

      writeLog(1, rcm->src, shour, smin, ssec, TOS_NODE_ID, cur_hour, cur_min, cur_sec);
      dbg("RadioCountToLedsC", "%d:%02d:%02d Node %d Received packet %d of length %hhu from Node %d.\n", cur_hour, cur_min, cur_sec, TOS_NODE_ID, rcm->counter, len, rcm->src);


      if (rcm->counter & 0x1) {
	call Leds.led0On();
      }
      else {
	call Leds.led0Off();
      }
      if (rcm->counter & 0x2) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (rcm->counter & 0x4) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
	dbg("RadioCountToLedsC", "RadioCountToLedsC: packet sent.\n");	
      locked = FALSE;
    }
  }

}



