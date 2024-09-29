interface NeighborDiscovery {
    command void startDiscovery();
    command void processPacket(message_t* msg, void* payload, uint8_t len);
    command void printNeighbors();
    event void neighborAdded(uint16_t neighborID);
}
