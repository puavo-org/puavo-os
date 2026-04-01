CC = gcc
CFLAGS = -Wall -Wextra -std=gnu99
LDFLAGS = $(shell pkg-config --libs libcrypto)

puavo-command-line-sign-prepare: prepare.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f puavo-command-line-sign-prepare

.PHONY: clean
