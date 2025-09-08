#include "parser.h"
#include <stdio.h>
#include <string.h>

/* this is the upgraded main.c function , and is what is used for test.c
Key Difference:
-displays complete and all fields of ipv4 and ipv6, main.c only displayed select few field
-has checks integrated incase the packet is indifferent

*/
static void print_mac(const uint8_t *mac) {
    printf("%02X:%02X:%02X:%02X:%02X:%02X",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

static void print_ipv4_addr(uint32_t ip) {
    printf("%u.%u.%u.%u",
           (unsigned)((ip >> 24) & 0xFF),
           (unsigned)((ip >> 16) & 0xFF),
           (unsigned)((ip >> 8)  & 0xFF),
           (unsigned)( ip        & 0xFF));
}

static void print_ipv6_addr(const uint8_t *ip) {
    for (int i = 0; i < 16; i += 2) {
        printf("%02X%02X", ip[i], ip[i+1]);
        if (i < 14) printf(":");
    }
}

static void print_ethernet(const ethernet_header_t *eth) {
    printf("Ethernet:\n");
    printf("  DST MAC: "); print_mac(eth->dst_mac); printf("\n");
    printf("  SRC MAC: "); print_mac(eth->src_mac); printf("\n");
    printf("  Ethertype: 0x%04X\n", eth->ethertype);
}

static void print_ipv4_header(const ipv4_header_t *ip) {
    printf("IPv4 Header:\n");
    printf("  Version: %u\n", (unsigned)ip->version);
    printf("  IHL: %u (words)\n", (unsigned)ip->ihl);
    printf("  DSCP: %u\n", (unsigned)ip->dscp);
    printf("  ECN: %u\n", (unsigned)ip->ecn);
    printf("  Total Length: %u\n", (unsigned)ip->total_length);
    printf("  Identification: 0x%04X\n", (unsigned)ip->identification);
    printf("  Flags: 0x%X\n", (unsigned)ip->flags);
    printf("  Fragment Offset: %u\n", (unsigned)ip->fragment_offset);
    printf("  TTL: %u\n", (unsigned)ip->ttl);
    printf("  Protocol: %u\n", (unsigned)ip->protocol);
    printf("  Header Checksum: 0x%04X\n", (unsigned)ip->hdr_checksum);
    printf("  Src IP: "); print_ipv4_addr(ip->src_ip); printf("\n");
    printf("  Dst IP: "); print_ipv4_addr(ip->dst_ip); printf("\n");
}

static void print_ipv6_header(const ipv6_header_t *ip) {
    printf("IPv6 Header:\n");
    printf("  Version: %u\n", (unsigned)ip->version);
    printf("  Traffic Class: %u\n", (unsigned)ip->traffic_class);
    printf("  Flow Label: %u\n", (unsigned)ip->flow_label);
    printf("  Payload Length: %u\n", (unsigned)ip->payload_len);
    printf("  Next Header: %u\n", (unsigned)ip->next_header);
    printf("  Hop Limit: %u\n", (unsigned)ip->hop_limit);
    printf("  Src IP: "); print_ipv6_addr(ip->src_ip); printf("\n");
    printf("  Dst IP: "); print_ipv6_addr(ip->dst_ip); printf("\n");
}

void parse_packet(const uint8_t *frame, size_t len, parser_t *ctx) {
    if (!frame || !ctx) return;

    ctx->is_ipv4 = 0;
    ctx->is_ipv6 = 0;
    memset(&ctx->ip_hdr, 0, sizeof(ctx->ip_hdr));

    if (len < 14) {
        printf("Frame too short (%zu bytes). Need >= 14 bytes for Ethernet header.\n", len);
        return;
    }

    parse_ethernet(frame, &ctx->eth_hdr);
    print_ethernet(&ctx->eth_hdr);

    if (ctx->eth_hdr.ethertype == 0x0800) {
        if (len < 14 + 20) {
            printf("Frame too short for IPv4 header (have %zu bytes)\n", len);
            return;
        }
        ctx->is_ipv4 = 1;
        parse_ipv4(frame + 14, &ctx->ip_hdr.ipv4);
        print_ipv4_header(&ctx->ip_hdr.ipv4);
    } else if (ctx->eth_hdr.ethertype == 0x86DD) {
        if (len < 14 + 40) {
            printf("Frame too short for IPv6 header (have %zu bytes)\n", len);
            return;
        }
        ctx->is_ipv6 = 1;
        parse_ipv6(frame + 14, &ctx->ip_hdr.ipv6);
        print_ipv6_header(&ctx->ip_hdr.ipv6);
    } else {
        printf("Unsupported Ethertype 0x%04X — not IPv4/IPv6\n", ctx->eth_hdr.ethertype);
    }
}
