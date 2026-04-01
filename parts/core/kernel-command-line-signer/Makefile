prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

SBSIGNTOOLS_DIRECTORY = $(CURDIR)/.sbsigntools
MODULES_ROOT ?= /lib/modules

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
# Build
#

.PHONY: all
all: userspace modules

.PHONY: userspace
userspace: setup
	for directory in $(SUBDIRECTORIES); do \
		if [ "$$directory" = "sign" ]; then \
			$(MAKE) -C $$directory userspace; \
		else \
			$(MAKE) -C $$directory; \
		fi; \
	done

.PHONY: modules
modules: setup
    # Build kernel modules for each kernel version in MODULES_ROOT
	for version in $$(ls $(MODULES_ROOT)); do \
		build_directory="$(MODULES_ROOT)/$$version/build"; \
		if [ -d "$$build_directory" ]; then \
			echo "Building module for kernel $$version..."; \
			$(MAKE) -C sign modules \
				KERNEL_BUILD_DIRECTORY="$$build_directory"; \
			mkdir -p $(CURDIR)/sign/modules/$$version; \
			mv sign/puavo_command_line_signer.ko \
				$(CURDIR)/sign/modules/$$version/; \
		else \
			echo "Skipping kernel $$version" \
				"(no build directory)"; \
		fi; \
	done

#
# Install
#

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY: install
install: all install-directories
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
	# Install kernel modules for each kernel version in MODULES_ROOT
	for version in $$(ls $(MODULES_ROOT)); do \
		module="sign/modules/$$version/puavo_command_line_signer.ko"; \
		if [ -f "$$module" ]; then \
			mkdir -p \
				$(DESTDIR)/lib/modules/$$version/extra/; \
			$(INSTALL) -m 644 "$$module" \
				$(DESTDIR)/lib/modules/$$version/extra/; \
		fi; \
	done

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
	rm -rf sign/modules
