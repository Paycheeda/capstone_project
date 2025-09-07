CC = gcc
CFLAGS = -Wall -Wextra

OBJS = main.o ethernet_header_parser.o ipv4_header_parser.o ipv6_header_parser.o

all: parser

parser: $(OBJS)
	$(CC) $(CFLAGS) -o parser $(OBJS)

main.o: main.c parser.h
ethernet_header_parser.o: ethernet_header_parser.c parser.h
ipv4_header_parser.o: ipv4_header_parser.c parser.h
ipv6_header_parser.o: ipv6_header_parser.c parser.h

clean:
	rm -f *.o parser
