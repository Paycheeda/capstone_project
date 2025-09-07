#include <stdio.h>
#include "parser.h"

int main() {
    // Example Ethernet frame (dummy data)
    uint8_t frame[14] = {
        0x01,0x02,0x03,0x04,0x05,0x06, // dst_mac
        0x11,0x12,0x13,0x14,0x15,0x16, // src_mac
        0x08,0x00                      // ethertype = IPv4
    };

    ethernet_header_t eth;
    parse_ethernet(frame, &eth);

    printf("Dst MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
        eth.dst_mac[0], eth.dst_mac[1], eth.dst_mac[2],
        eth.dst_mac[3], eth.dst_mac[4], eth.dst_mac[5]);
    printf("Src MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
        eth.src_mac[0], eth.src_mac[1], eth.src_mac[2],
        eth.src_mac[3], eth.src_mac[4], eth.src_mac[5]);
    printf("Ethertype: 0x%04x\n", eth.ethertype);

    return 0;
}
