prefix = /usr
exec_prefix = $(prefix)
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

SBSIGNTOOLS_DIRECTORY = $(CURDIR)/.sbsigntools

SUBDIRECTORIES = request assemble

TPM_SCRIPTS = authorize counter load placeholder-keys sign

export SBSIGNTOOLS_DIRECTORY

$(SBSIGNTOOLS_DIRECTORY)/.fetched:
	$(CURDIR)/scripts/setup \
		$(SBSIGNTOOLS_DIRECTORY) $(CURDIR)/patches

.PHONY: setup
setup: $(SBSIGNTOOLS_DIRECTORY)/.fetched

.PHONY: all
all: setup
	for directory in $(SUBDIRECTORIES); do \
		$(MAKE) -C $$directory; \
	done

.PHONY: install
install: all
	mkdir -p $(DESTDIR)$(sbindir) $(DESTDIR)$(libdir)/puavo-core
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		request/puavo-command-line-sign-request \
		assemble/puavo-command-line-sign-assemble
	for script in $(TPM_SCRIPTS); do \
		$(INSTALL_PROGRAM) tpm/$$script \
			$(DESTDIR)$(libdir)/puavo-core/puavo-command-line-manager-$$script; \
	done

.PHONY: test
test:
	tests/command-line-manager.sh

.PHONY: format
format:
	clang-format -i \
		request/request.c \
		assemble/assemble.c

.PHONY: clean
clean:
	for directory in $(SUBDIRECTORIES); do \
		$(MAKE) -C $$directory clean; \
	done
	rm -rf $(SBSIGNTOOLS_DIRECTORY)
