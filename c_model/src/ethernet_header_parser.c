
#include "parser.h"
#include <string.h>
#include <stdint.h>

/*only the ethernet parser module*/

void parse_ethernet(const uint8_t *frame, ethernet_header_t *eth_hdr) {
    if (!frame || !eth_hdr) return;
    memcpy(eth_hdr->dst_mac, frame, 6);
    memcpy(eth_hdr->src_mac, frame + 6, 6);
    eth_hdr->ethertype = (uint16_t)((uint16_t)frame[12] << 8) | (uint16_t)frame[13];
}
