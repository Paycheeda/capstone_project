#include "parser.h"

void parse_ipv4(const uint8_t *packet, ipv4_header_t *ipv4_hdr) {
    // Version + IHL
    ipv4_hdr->version = (packet[0] >> 4) & 0x0F;
    ipv4_hdr->ihl     = packet[0] & 0x0F;

    // DSCP + ECN
    ipv4_hdr->dscp = (packet[1] >> 2) & 0x3F;
    ipv4_hdr->ecn  = packet[1] & 0x03;

    ipv4_hdr->total_length   = (packet[2] << 8) | packet[3];
    ipv4_hdr->identification = (packet[4] << 8) | packet[5];

    // Flags + Fragment Offset
    ipv4_hdr->flags           = (packet[6] >> 5) & 0x07;
    ipv4_hdr->fragment_offset = ((packet[6] & 0x1F) << 8) | packet[7];

    ipv4_hdr->ttl          = packet[8];
    ipv4_hdr->protocol     = packet[9];
    ipv4_hdr->hdr_checksum = (packet[10] << 8) | packet[11];

    ipv4_hdr->src_ip = (packet[12] << 24) | (packet[13] << 16) |
                       (packet[14] << 8) | packet[15];

    ipv4_hdr->dst_ip = (packet[16] << 24) | (packet[17] << 16) |
                       (packet[18] << 8) | packet[19];
}
