SBSIGN = $(SBSIGNTOOLS_DIRECTORY)
SRC = $(SBSIGN)/src
CCAN = $(SBSIGN)/lib/ccan

CC = gcc
CFLAGS = -Wall -Wextra --std=gnu99 \
	-I$(SRC) -I$(CCAN) \
	-DVERSION=\"1.0\" \
	-DHAVE_LITTLE_ENDIAN=1 \
	-DHAVE_BIG_ENDIAN=0 \
	-DOPENSSL_API_COMPAT=0x10100000L
LDFLAGS = $(shell pkg-config --libs libcrypto)

SBSIGN_SRCS = $(SRC)/image.c $(SRC)/idc.c \
	$(SRC)/fileio.c
CCAN_SRCS = $(CCAN)/ccan/talloc/talloc.c \
	$(CCAN)/ccan/read_write_all/read_write_all.c

puavo-command-line-sign-request: request.c \
		$(SBSIGN_SRCS) $(CCAN_SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f puavo-command-line-sign-request

.PHONY: clean
