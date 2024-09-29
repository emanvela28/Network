module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Timer<TMilli> as HelloTimer;
    uses interface SimpleSend as Sender;
    uses interface Receive;
}

implementation {
    uint16_t neighborList[10];
    uint8_t neighborCount = 0;
    pack sendPackage;

    // makePack function must be placed above any call to it to avoid implicit declaration
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void NeighborDiscovery.startDiscovery() {
        call HelloTimer.startPeriodic(2000);
    }

    event void HelloTimer.fired() {
        uint8_t payload[2];

        dbg(NEIGHBOR_CHANNEL, "HelloTimer Fired, sending hello message\n");
        payload[0] = (uint8_t)(TOS_NODE_ID & 0xFF);
        payload[1] = (uint8_t)((TOS_NODE_ID >> 8) & 0xFF);

        makePack(&sendPackage, TOS_NODE_ID, 0xFFFF, 1, 1, 0, payload, sizeof(payload));  // Use makePack here
        call Sender.send(sendPackage, 0xFFFF);  // Broadcast to all neighbors
    }

    command void NeighborDiscovery.processPacket(message_t* msg, void* payload, uint8_t len) {
        uint16_t senderNodeID;
        bool isNeighbor = FALSE;
        uint8_t i;

        if (len == sizeof(pack)) {
            pack* myMsg = (pack*)payload;

            senderNodeID = (myMsg->payload[1] << 8) | myMsg->payload[0];
            dbg(NEIGHBOR_CHANNEL, "Sender Node ID: %d\n", senderNodeID);

            for (i = 0; i < neighborCount; i++) {
                if (neighborList[i] == senderNodeID) {
                    isNeighbor = TRUE;
                    break;
                }
            }

            if (!isNeighbor && neighborCount < 10) {
                neighborList[neighborCount] = senderNodeID;
                neighborCount++;
                dbg(NEIGHBOR_CHANNEL, "New Neighbor added: %d\n", senderNodeID);
                signal NeighborDiscovery.neighborAdded(senderNodeID);  // Signal the event
            } else if (isNeighbor) {
                dbg(NEIGHBOR_CHANNEL, "Neighbor already known: %d\n", senderNodeID);
            } else {
                dbg(NEIGHBOR_CHANNEL, "Neighbor list is full!\n");
            }
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        call NeighborDiscovery.processPacket(msg, payload, len);  // Delegate processing to processPacket command
        return msg;
    }

    command void NeighborDiscovery.printNeighbors() {
        uint8_t i;
        dbg(NEIGHBOR_CHANNEL, "Neighbor List:\n");
        if (neighborCount == 0) {
            dbg(NEIGHBOR_CHANNEL, "No neighbors discovered yet.\n");
        }
        for (i = 0; i < neighborCount; i++) {
            dbg(NEIGHBOR_CHANNEL, "Neighbor %d: Node ID = %d\n", i + 1, neighborList[i]);
        }
    }
}
