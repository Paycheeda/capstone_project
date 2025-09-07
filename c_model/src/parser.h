#ifndef PARSER_H
#define PARSER_H

#include <stdint.h>

// Ethernet header
typedef struct {
    uint8_t  dst_mac[6];
    uint8_t  src_mac[6];
    uint16_t ethertype;   // 0x0800 = IPv4, 0x86DD = IPv6
} ethernet_header_t;

// IPv4 header (simplified)
typedef struct {
    uint8_t  version_ihl;
    uint8_t  tos;
    uint16_t total_length;
    uint16_t identification;
    uint16_t flags_fragment;
    uint8_t  ttl;
    uint8_t  protocol;
    uint16_t hdr_checksum;
    uint32_t src_ip;
    uint32_t dst_ip;
} ipv4_header_t;

// IPv6 header (simplified)
typedef struct {
    uint32_t ver_tc_fl;
    uint16_t payload_len;
    uint8_t  next_header;
    uint8_t  hop_limit;
    uint8_t  src_ip[16];
    uint8_t  dst_ip[16];
} ipv6_header_t;

// Union for protocol-specific headers
typedef union {
    ipv4_header_t ipv4;
    ipv6_header_t ipv6;
} ip_header_u;

// Parser context
typedef struct {
    ethernet_header_t eth_hdr;
    ip_header_u       ip_hdr;
    int               is_ipv4;
    int               is_ipv6;
} parser_t;

// Function prototypes
void parse_ethernet(const uint8_t *frame, ethernet_header_t *eth_hdr);
void parse_ipv4(const uint8_t *packet, ipv4_header_t *ipv4_hdr);
void parse_ipv6(const uint8_t *packet, ipv6_header_t *ipv6_hdr);

#endif // PARSER_H
