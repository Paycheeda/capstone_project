CC = gcc
CFLAGS = -Wall -Wextra -g

OBJS = ethernet_header_parser.o ipv4_header_parser.o ipv6_header_parser.o main.o

all: test

main.o: main.c parser.h
	$(CC) $(CFLAGS) -c main.c

ethernet_header_parser.o: ethernet_header_parser.c parser.h
	$(CC) $(CFLAGS) -c ethernet_header_parser.c

ipv4_header_parser.o: ipv4_header_parser.c parser.h
	$(CC) $(CFLAGS) -c ipv4_header_parser.c

ipv6_header_parser.o: ipv6_header_parser.c parser.h
	$(CC) $(CFLAGS) -c ipv6_header_parser.c

test.o: test.c parser.h
	$(CC) $(CFLAGS) -c test.c

test: $(OBJS) test.o
	$(CC) $(CFLAGS) -o test $(OBJS) test.o

clean:
	rm -f *.o test
