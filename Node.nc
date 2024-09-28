/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface Flooding;

   uses interface NeighborDiscovery;

   uses interface Timer<TMilli> as HelloTimer;
}

implementation{
   pack sendPackage;

   //Making a list for the neighbors
   uint16_t neighborList[10];
   uint8_t neighborCount = 0;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      call HelloTimer.startPeriodic(2000);
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void HelloTimer.fired() {
      // Variable Declarations before the code
      uint8_t payload[2];

      
      dbg(GENERAL_CHANNEL, "HelloTimer Fired, sending hello message\n");
      //Creating hello message

      payload[0] = (uint8_t)(TOS_NODE_ID & 0xFF);
      payload[1] = (uint8_t)((TOS_NODE_ID >> 8) & 0xFF);

      // Send the hello message to all neighbors (broadcast)
      makePack(&sendPackage, TOS_NODE_ID, 0xFFFF, 1, 1, 0, payload, sizeof(payload));
      // Broadcast to all neighbors (0xFFFF)
      call Sender.send(sendPackage, 0xFFFF); 

   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      //Variable Definitions, getting weird error with them being defined later in code
      uint16_t senderNodeID;
      bool isNeighbor = FALSE;
      uint8_t i;


      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg = (pack*) payload;

         //Valid Packet received
         dbg(GENERAL_CHANNEL, "Valid Packet Received.\n");

         // Extract the senders node id and rebuild to 16 bits
         senderNodeID = (myMsg->payload[1] << 8) | myMsg->payload[0];

         //dbg to show the extracted id
         dbg(GENERAL_CHANNEL, "Sender Node ID: %d\n", senderNodeID);

         // Checking to see if the neighbor is in the cache
         for (i = 0; i < neighborCount; i++) {
            if (neighborList[i] == senderNodeID) {
               isNeighbor = TRUE;
               break;
            }
         }

         //Adding the neighbor to the cache if it is not already in there
         if (!isNeighbor && neighborCount < 10) {
            neighborList[neighborCount] = senderNodeID;
            neighborCount++;
            dbg(GENERAL_CHANNEL, "New Neighbor added: %d\n", senderNodeID);
         } else if (isNeighbor) { 
            dbg(GENERAL_CHANNEL, "Neighbor already known: %d\n", senderNodeID);
         } else {
             dbg(GENERAL_CHANNEL, "Neighbor list is full!\n");
         }

         //return the message after the processing
         return msg;

      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){
      //Variable declarations 
      uint8_t i;

      dbg(GENERAL_CHANNEL, "Neighbor List:\n");

      //Checking for neighbors
      if (neighborCount == 0) {
         dbg(GENERAL_CHANNEL, " No neighbors discovered yet.\n");
         return;
      }

      //Looping through the neighbors list to print the neighbors ID
      for (i = 0; i < neighborCount; i++) {
         dbg(GENERAL_CHANNEL, "Neighbor %d: Node ID = %d\n", i + 1, neighborList[i]);
      }
   }

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
