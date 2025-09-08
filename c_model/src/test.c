#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "parser.h"

size_t generate_ipv4_packet(uint8_t *buf);
size_t generate_ipv6_packet(uint8_t *buf);

int main(void) {
    srand((unsigned)time(NULL));

    const int N = 5;
    uint8_t buf[1500];
    parser_t ctx;

    for (int i = 0; i < N; ++i) {
        printf("\n===== Packet %d =====\n", i + 1);
        size_t len;
        if ((rand() & 1) == 0) {
            len = generate_ipv4_packet(buf);
            printf("[generated IPv4 packet length=%zu]\n", len);
        } else {
            len = generate_ipv6_packet(buf);
            printf("[generated IPv6 packet length=%zu]\n", len);
        }
        parse_packet(buf, len, &ctx);
    }
    return 0;
}
