prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

SBSIGNTOOLS_DIRECTORY = $(CURDIR)/.sbsigntools

DKMS_NAME = puavo-command-line-signer
DKMS_VERSION = 1.0
DKMS_SOURCE_DIRECTORY = $(DESTDIR)/usr/src/$(DKMS_NAME)-$(DKMS_VERSION)

SUBDIRECTORIES = prepare request sign assemble

export SBSIGNTOOLS_DIRECTORY

#
# Setup
#

$(SBSIGNTOOLS_DIRECTORY)/.fetched:
	$(CURDIR)/scripts/setup \
		$(SBSIGNTOOLS_DIRECTORY) $(CURDIR)/patches

.PHONY: setup
setup: $(SBSIGNTOOLS_DIRECTORY)/.fetched

#
# Build (userspace tools only, kernel module is
# built by DKMS after kernel packages are installed)
#

.PHONY: all
all: userspace

.PHONY: userspace
userspace: setup
	for directory in $(SUBDIRECTORIES); do \
		if [ "$$directory" = "sign" ]; then \
			$(MAKE) -C $$directory userspace; \
		else \
			$(MAKE) -C $$directory; \
		fi; \
	done

#
# Install
#

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY: install
install: all install-directories install-dkms-source
	$(INSTALL_PROGRAM) \
		prepare/puavo-command-line-sign-prepare \
		$(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) \
		request/puavo-command-line-sign-request \
		$(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) \
		sign/puavo-command-line-sign \
		$(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) \
		assemble/puavo-command-line-sign-assemble \
		$(DESTDIR)$(sbindir)/

# Install kernel module source for DKMS.
.PHONY: install-dkms-source
install-dkms-source:
	mkdir -p $(DKMS_SOURCE_DIRECTORY)
	$(INSTALL_DATA) sign/dkms.conf \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/Kbuild \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/kernel_module.c \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/core.c \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/core.h \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/der.c \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/der.h \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/authenticode.c \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/authenticode.h \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/pe.h \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/log.h \
		$(DKMS_SOURCE_DIRECTORY)/
	$(INSTALL_DATA) sign/ioctl.h \
		$(DKMS_SOURCE_DIRECTORY)/

#
# Test
#

.PHONY: test
test: userspace
	$(CURDIR)/scripts/test

#
# Format
#

.PHONY: format
format:
	clang-format -i \
		prepare/prepare.c \
		request/request.c \
		assemble/assemble.c \
		sign/core.c \
		sign/core.h \
		sign/ioctl.h \
		sign/sign.c \
		sign/user_backend.c \
		sign/user_backend.h \
		sign/kernel_client.c \
		sign/kernel_client.h \
		sign/kernel_module.c \
		sign/pe.h \
		sign/log.h \
		sign/der.c \
		sign/der.h \
		sign/authenticode.c \
		sign/authenticode.h

#
# Clean
#

.PHONY: clean
clean:
	for directory in $(SUBDIRECTORIES); do \
		$(MAKE) -C $$directory clean; \
	done
	rm -rf $(SBSIGNTOOLS_DIRECTORY)

