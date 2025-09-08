#include "parser.h"
#include <stdint.h>

/*IPV4 parser module*/

void parse_ipv4(const uint8_t *packet, ipv4_header_t *ipv4_hdr) {
    if (!packet || !ipv4_hdr) return;

    ipv4_hdr->version = (uint8_t)((packet[0] >> 4) & 0x0F);
    ipv4_hdr->ihl     = (uint8_t)(packet[0] & 0x0F);

    ipv4_hdr->dscp = (uint8_t)((packet[1] >> 2) & 0x3F);
    ipv4_hdr->ecn  = (uint8_t)(packet[1] & 0x03);

    ipv4_hdr->total_length   = (uint16_t)((uint16_t)packet[2] << 8) | (uint16_t)packet[3];
    ipv4_hdr->identification = (uint16_t)((uint16_t)packet[4] << 8) | (uint16_t)packet[5];

    ipv4_hdr->flags = (uint16_t)((packet[6] >> 5) & 0x07);
    ipv4_hdr->fragment_offset = (uint16_t)(((uint16_t)(packet[6] & 0x1F) << 8) | (uint16_t)packet[7]);

    ipv4_hdr->ttl          = packet[8];
    ipv4_hdr->protocol     = packet[9];
    ipv4_hdr->hdr_checksum = (uint16_t)((uint16_t)packet[10] << 8) | (uint16_t)packet[11];

    ipv4_hdr->src_ip = (uint32_t)((uint32_t)packet[12] << 24) |
                       (uint32_t)((uint32_t)packet[13] << 16) |
                       (uint32_t)((uint32_t)packet[14] << 8)  |
                       (uint32_t)packet[15];

    ipv4_hdr->dst_ip = (uint32_t)((uint32_t)packet[16] << 24) |
                       (uint32_t)((uint32_t)packet[17] << 16) |
                       (uint32_t)((uint32_t)packet[18] << 8)  |
                       (uint32_t)packet[19];
}
