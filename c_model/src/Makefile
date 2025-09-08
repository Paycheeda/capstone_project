CC = gcc
CFLAGS = -Wall -Wextra -g

SRCS = ethernet_header_parser.c ipv4_header_parser.c ipv6_header_parser.c \
       packet_generator.c parser.c test.c
OBJS = $(SRCS:.c=.o)
TARGET = test

all: $(TARGET)

%.o: %.c parser.h
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
