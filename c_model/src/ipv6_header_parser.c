#include "parser.h"
#include <string.h>

void parse_ipv6(const uint8_t *packet, ipv6_header_t *ipv6_hdr) {
    // First 4 bytes = Version (4), Traffic Class (8), Flow Label (20)
    ipv6_hdr->version       = (packet[0] >> 4) & 0x0F;
    ipv6_hdr->traffic_class = ((packet[0] & 0x0F) << 4) | (packet[1] >> 4);
    ipv6_hdr->flow_label    = ((packet[1] & 0x0F) << 16) | (packet[2] << 8) | packet[3];

    ipv6_hdr->payload_len = (packet[4] << 8) | packet[5];
    ipv6_hdr->next_header = packet[6];
    ipv6_hdr->hop_limit   = packet[7];

    memcpy(ipv6_hdr->src_ip, packet + 8, 16);
    memcpy(ipv6_hdr->dst_ip, packet + 24, 16);
}
