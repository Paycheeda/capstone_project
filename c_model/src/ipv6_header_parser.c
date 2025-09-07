#include "parser.h"
#include <string.h>

void parse_ipv6(const uint8_t *packet, ipv6_header_t *ipv6_hdr) {
    ipv6_hdr->ver_tc_fl   = (packet[0] << 24) | (packet[1] << 16) |
                            (packet[2] << 8) | packet[3];
    ipv6_hdr->payload_len = (packet[4] << 8) | packet[5];
    ipv6_hdr->next_header = packet[6];
    ipv6_hdr->hop_limit   = packet[7];
    memcpy(ipv6_hdr->src_ip, packet + 8, 16);
    memcpy(ipv6_hdr->dst_ip, packet + 24, 16);
}
