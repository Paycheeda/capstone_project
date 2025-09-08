#include "parser.h"
#include <string.h>
#include <stdint.h>

/*ipv6 parser module*/

void parse_ipv6(const uint8_t *packet, ipv6_header_t *ipv6_hdr) {
    if (!packet || !ipv6_hdr) return;

    ipv6_hdr->version = (uint8_t)((packet[0] >> 4) & 0x0F);
    ipv6_hdr->traffic_class = (uint8_t)(((packet[0] & 0x0F) << 4) | ((packet[1] >> 4) & 0x0F));
    ipv6_hdr->flow_label = (uint32_t)(((uint32_t)(packet[1] & 0x0F) << 16) |
                                      ((uint32_t)packet[2] << 8) |
                                      (uint32_t)packet[3]);
    ipv6_hdr->payload_len = (uint16_t)((uint16_t)packet[4] << 8) | (uint16_t)packet[5];
    ipv6_hdr->next_header = packet[6];
    ipv6_hdr->hop_limit   = packet[7];

    memcpy(ipv6_hdr->src_ip, packet + 8, 16);
    memcpy(ipv6_hdr->dst_ip, packet + 24, 16);
}
