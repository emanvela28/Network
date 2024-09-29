module Node {
    uses interface Boot;
    uses interface SplitControl as AMControl;
    uses interface Receive;
    uses interface SimpleSend as Sender;
    uses interface CommandHandler;
    uses interface NeighborDiscovery;
    uses interface Timer<TMilli> as HelloTimer;  // This is the Timer for neighbor discovery
    uses interface Flooding;
}

implementation {
    pack sendPackage;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);

    // Boot event
    event void Boot.booted() {
        call AMControl.start();
        dbg(GENERAL_CHANNEL, "Booted\n");
        call NeighborDiscovery.startDiscovery();  // Start neighbor discovery
        call HelloTimer.startPeriodic(2000);      // Start the periodic timer for neighbor discovery
    }

    // AMControl start done event
    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            dbg(GENERAL_CHANNEL, "Radio On\n");
        } else {
            call AMControl.start();  // Retry if failed
        }
    }

    event void AMControl.stopDone(error_t err) {}

    // Receive message event
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        dbg(GENERAL_CHANNEL, "Packet Received\n");
        call NeighborDiscovery.processPacket(msg, payload, len);  // Delegate neighbor discovery to NeighborDiscoveryP
        return msg;
    }

    // Timer fired event (HelloTimer.fired)
    event void HelloTimer.fired() {
        dbg(GENERAL_CHANNEL, "HelloTimer fired - sending neighbor discovery message\n");
        // Neighbor discovery ping or broadcasting can go here
        call NeighborDiscovery.startDiscovery();  // You can trigger neighbor discovery again periodically if needed
    }

    // CommandHandler ping event
    event void CommandHandler.ping(uint16_t destination, uint8_t* payload) {
        dbg(GENERAL_CHANNEL, "PING EVENT\n");
        makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, destination);
    }

    event void CommandHandler.printNeighbors() {
        call NeighborDiscovery.printNeighbors();  // Print neighbors via NeighborDiscoveryP
    }

    // Implementing the NeighborDiscovery.neighborAdded event
    event void NeighborDiscovery.neighborAdded(uint16_t neighborID) {
        dbg(GENERAL_CHANNEL, "Neighbor discovered: %d\n", neighborID);
    }

    // Empty event implementations for CommandHandler to avoid errors
    event void CommandHandler.printLinkState() {}
    event void CommandHandler.printDistanceVector() {}
    event void CommandHandler.setTestServer() {}
    event void CommandHandler.setTestClient() {}
    event void CommandHandler.setAppServer() {}
    event void CommandHandler.setAppClient() {}
    event void CommandHandler.printRouteTable() {}

    void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}
