SBSIGN = $(SBSIGNTOOLS_DIRECTORY)
SRC = $(SBSIGN)/src
CCAN = $(SBSIGN)/lib/ccan

#
# Userspace build
#

CC = gcc
CFLAGS = -Wall -Wextra -std=gnu99 \
	-I$(SRC) -I$(CCAN) \
	-DVERSION=\"1.0\" \
	-DHAVE_LITTLE_ENDIAN=1 \
	-DHAVE_BIG_ENDIAN=0 \
	-DOPENSSL_API_COMPAT=0x10100000L \
	$(shell pkg-config --cflags libcrypto)
LDFLAGS = $(shell pkg-config --libs libcrypto)

SBSIGN_SRCS = $(SRC)/fileio.c
CCAN_SRCS = $(CCAN)/ccan/talloc/talloc.c \
	$(CCAN)/ccan/read_write_all/read_write_all.c

SIGN_SRCS = sign.c user_backend.c kernel_client.c \
	core.c der.c authenticode.c
SIGN_HDRS = core.h ioctl.h log.h pe.h der.h \
	authenticode.h user_backend.h kernel_client.h

puavo-command-line-sign: $(SIGN_SRCS) $(SIGN_HDRS) \
		$(SBSIGN_SRCS) $(CCAN_SRCS)
	$(CC) $(CFLAGS) -o $@ $(SIGN_SRCS) \
		$(SBSIGN_SRCS) $(CCAN_SRCS) $(LDFLAGS)

#
# Kernel module build
#
# KERNEL_BUILD_DIRECTORY must be set by the caller
# when building modules (e.g. the top-level Makefile
# sets it per kernel version).
#

KERNEL_BUILD_DIRECTORY ?= /lib/modules/$(shell uname -r)/build

obj-m := puavo_command_line_signer.o
puavo_command_line_signer-y := \
	kernel_module.o core.o der.o authenticode.o

modules:
	$(MAKE) -C $(KERNEL_BUILD_DIRECTORY) \
		M=$(CURDIR) modules

modules_clean:
	$(MAKE) -C $(KERNEL_BUILD_DIRECTORY) \
		M=$(CURDIR) clean

#
# Combined targets
#

userspace: puavo-command-line-sign

all: puavo-command-line-sign modules

clean: modules_clean
	rm -f puavo-command-line-sign

.PHONY: all userspace clean modules modules_clean
