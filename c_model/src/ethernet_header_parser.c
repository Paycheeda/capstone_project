
#include "parser.h"
#include <string.h>
#include <stdint.h>

void parse_ethernet(const uint8_t *frame, ethernet_header_t *eth_hdr) {
    if (!frame || !eth_hdr) return;
    memcpy(eth_hdr->dst_mac, frame, 6);
    memcpy(eth_hdr->src_mac, frame + 6, 6);
    /* ethertype is two bytes in network (big-endian) order */
    eth_hdr->ethertype = (uint16_t)((uint16_t)frame[12] << 8) | (uint16_t)frame[13];
}
