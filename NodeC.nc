/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC {
    provides {
        interface Boot;
    }
}

implementation {
    components MainC;
    components Node;
    components FloodingP;
    components NeighborDiscoveryP;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new TimerMilliC() as HelloTimerMilliC;  // Using TimerMilliC for HelloTimer

    // Properly connecting Boot to MainC.Boot
    Boot = MainC.Boot;

    // Wiring Receive interface
    Node.Receive -> GeneralReceive;

    // Wiring HelloTimer used in NeighborDiscoveryP to HelloTimerMilliC
    NeighborDiscoveryP.HelloTimer -> HelloTimerMilliC;  // Wire NeighborDiscoveryP's HelloTimer to TimerMilliC

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    // Wiring SimpleSend interface for sending messages
    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;               // Node is wired to SimpleSendC
    NeighborDiscoveryP.Sender -> SimpleSendC; // Wire NeighborDiscoveryP.Sender to SimpleSendC

    // Wiring CommandHandler
    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    // Wiring Flooding
    components FloodingC;
    Node.Flooding -> FloodingC;

    // Wiring NeighborDiscovery
    components NeighborDiscoveryC;
    Node.NeighborDiscovery -> NeighborDiscoveryC;
}
