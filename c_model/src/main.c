#include <stdio.h>
#include <string.h>
#include "parser.h"

/*
main module which connected ethernet parser to ipv4 and ipv6 parser

helpers to print more efficiently, benevolence of GPT
reason being, my old print function looked very amateur, wanted to make it look professional
*/

void print_mac(const uint8_t *mac) {
    printf("%02X:%02X:%02X:%02X:%02X:%02X",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

void print_ipv4(uint32_t ip) {
    printf("%u.%u.%u.%u",
           (ip >> 24) & 0xFF,
           (ip >> 16) & 0xFF,
           (ip >> 8) & 0xFF,
           ip & 0xFF);
}

void print_ipv6(const uint8_t *ip) {
    for (int i = 0; i < 16; i += 2) {
        printf("%02X%02X", ip[i], ip[i + 1]);
        if (i < 14) printf(":");
    }
}

/*printer functions for headers accordingly*/
void print_ethernet(const ethernet_header_t *eth) {
    printf("Ethernet Header:\n");
    printf("  Src MAC: "); print_mac(eth->src_mac); printf("\n");
    printf("  Dst MAC: "); print_mac(eth->dst_mac); printf("\n");
    printf("  Ethertype: 0x%04X\n", eth->ethertype);
}

void print_ipv4_header(const ipv4_header_t *ip) {
    printf("IPv4 Header:\n");
    printf("  Version: %u\n", ip->version);
    printf("  IHL: %u (words)\n", ip->ihl);
    printf("  DSCP: %u\n", ip->dscp);
    printf("  ECN: %u\n", ip->ecn);
    printf("  Total Length: %u\n", ip->total_length);
    printf("  Identification: %u\n", ip->identification);
    printf("  Flags: %u\n", ip->flags);
    printf("  Fragment Offset: %u\n", ip->fragment_offset);
    printf("  TTL: %u\n", ip->ttl);
    printf("  Protocol: %u\n", ip->protocol);
    printf("  Header Checksum: 0x%04X\n", ip->hdr_checksum);
    printf("  Src IP: "); print_ipv4(ip->src_ip); printf("\n");
    printf("  Dst IP: "); print_ipv4(ip->dst_ip); printf("\n");
}

void print_ipv6_header(const ipv6_header_t *ip) {
    printf("IPv6 Header:\n");
    printf("  Version: %u\n", ip->version);
    printf("  Traffic Class: %u\n", ip->traffic_class);
    printf("  Flow Label: %u\n", ip->flow_label);
    printf("  Payload Length: %u\n", ip->payload_len);
    printf("  Next Header: %u\n", ip->next_header);
    printf("  Hop Limit: %u\n", ip->hop_limit);
    printf("  Src IP: "); print_ipv6(ip->src_ip); printf("\n");
    printf("  Dst IP: "); print_ipv6(ip->dst_ip); printf("\n");
}

/* complete parser which parses the ethernet header then decides if to call ipv4 or ipv6 next*/
void parse_and_print(const uint8_t *frame, size_t len) {
    parser_t ctx = {0};

    if (len < 14) {
        printf("Frame too short for Ethernet\n");
        return;
    }

    parse_ethernet(frame, &ctx.eth_hdr);
    print_ethernet(&ctx.eth_hdr);

    switch (ctx.eth_hdr.ethertype) {
        case 0x0800: // IPv4
            if (len < 14 + 20) {
                printf("Frame too short for IPv4 header\n");
                return;
            }
            ctx.is_ipv4 = 1;
            parse_ipv4(frame + 14, &ctx.ip_hdr.ipv4);
            print_ipv4_header(&ctx.ip_hdr.ipv4);
            break;

        case 0x86DD: // IPv6
            if (len < 14 + 40) {
                printf("Frame too short for IPv6 header\n");
                return;
            }
            ctx.is_ipv6 = 1;
            parse_ipv6(frame + 14, &ctx.ip_hdr.ipv6);
            print_ipv6_header(&ctx.ip_hdr.ipv6);
            break;

        default:
            printf("Unsupported Ethertype: 0x%04X\n", ctx.eth_hdr.ethertype);
            break;
    }
}
