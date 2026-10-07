prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

SBSIGNTOOLS_DIRECTORY = $(CURDIR)/.sbsigntools

SUBDIRECTORIES = request assemble

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
	mkdir -p $(DESTDIR)$(sbindir)
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		request/puavo-command-line-sign-request \
		assemble/puavo-command-line-sign-assemble

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
