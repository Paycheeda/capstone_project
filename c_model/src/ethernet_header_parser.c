#include "parser.h"
#include <string.h>

void parse_ethernet(const uint8_t *frame, ethernet_header_t *eth_hdr) {
    memcpy(eth_hdr->dst_mac, frame, 6);
    memcpy(eth_hdr->src_mac, frame + 6, 6);
    eth_hdr->ethertype = (frame[12] << 8) | frame[13]; // network order
}
