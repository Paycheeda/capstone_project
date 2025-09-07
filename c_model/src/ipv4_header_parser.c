#include "parser.h"

void parse_ipv4(const uint8_t *packet, ipv4_header_t *ipv4_hdr) {
    ipv4_hdr->version_ihl    = packet[0];
    ipv4_hdr->tos            = packet[1];
    ipv4_hdr->total_length   = (packet[2] << 8) | packet[3];
    ipv4_hdr->identification = (packet[4] << 8) | packet[5];
    ipv4_hdr->flags_fragment = (packet[6] << 8) | packet[7];
    ipv4_hdr->ttl            = packet[8];
    ipv4_hdr->protocol       = packet[9];
    ipv4_hdr->hdr_checksum   = (packet[10] << 8) | packet[11];
    ipv4_hdr->src_ip         = (packet[12] << 24) | (packet[13] << 16) |
                               (packet[14] << 8) | packet[15];
    ipv4_hdr->dst_ip         = (packet[16] << 24) | (packet[17] << 16) |
                               (packet[18] << 8) | packet[19];
}
