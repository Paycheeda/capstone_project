#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "parser.h"
/*
the random packet generator
all of this is made by gpt, i was there to give the idea really, but for long tests i wanted a random packet generator
this does that, i understand it now , but ill explain line by line as well
*/


/* helpers are local to this file */
static void random_mac(uint8_t *mac) {
    for (int i = 0; i < 6; ++i) mac[i] = (uint8_t)(rand() % 256);
}

static uint8_t rand_byte(void) { return (uint8_t)(rand() % 256); }

static void random_ipv6(uint8_t *ip) {
    for (int i = 0; i < 16; ++i) ip[i] = rand_byte();
}

/* 
ethernet+ipv4 packet builder below
 */
size_t generate_ipv4_packet(uint8_t *buf) {
    uint8_t *p = buf;

    /* Ethernet header */
    random_mac(p);          /* dst */
    random_mac(p + 6);      /* src */
    p[12] = 0x08; p[13] = 0x00; /* ethertype IPv4 */
    p += 14;

    /* IPv4 header (20 bytes, without options) */
    p[0] = 0x45; /* ver=4, ihl=5 */
    p[1] = 0x00; /* dscp/ecn */
    /* total length: 20 bytes (header) -- no payload */
    p[2] = 0x00; p[3] = 0x14;
    p[4] = (uint8_t)(rand() % 256);
    p[5] = (uint8_t)(rand() % 256);
    p[6] = 0x40; p[7] = 0x00; /* flags + frag */
    p[8] = 64; /* ttl */
    p[9] = 6;  /* proto TCP */
    p[10] = 0; p[11] = 0; /* checksum placeholder */

    /* src ip and dst ip */
    for (int i = 0; i < 4; ++i) p[12 + i] = (uint8_t)(rand() % 256);
    for (int i = 0; i < 4; ++i) p[16 + i] = (uint8_t)(rand() % 256);

    return (size_t)(14 + 20);
}

/* 
ethernet+ipv6 packet builder below
*/
size_t generate_ipv6_packet(uint8_t *buf) {
    uint8_t *p = buf;

    /* Ethernet header */
    random_mac(p);           /* dst */
    random_mac(p + 6);       /* src */
    p[12] = 0x86; p[13] = 0xDD; /* ethertype IPv6 */
    p += 14;

    /* IPv6 header */
    p[0] = 0x60; p[1] = 0x00; p[2] = 0x00; p[3] = 0x00; /* ver, tc, flow */
    p[4] = 0x00; p[5] = 0x00; /* payload len = 0 */
    p[6] = 6;  /* next header (TCP) */
    p[7] = 64; /* hop limit */

    random_ipv6(p + 8);   /* src ip */
    random_ipv6(p + 24);  /* dst ip */

    return (size_t)(14 + 40);
}
