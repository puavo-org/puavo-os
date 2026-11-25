prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)$(sbindir)/
	mkdir -p $(DESTDIR)$(prefix)/lib/systemd/system/

.PHONY: install
install: install-directories
	$(INSTALL_PROGRAM) puavo-kps-fetcher $(DESTDIR)$(sbindir)/
	$(INSTALL_DATA) systemd/puavo-kps-fetcher.service \
		systemd/puavo-kps-fetcher.timer \
		$(DESTDIR)$(prefix)/lib/systemd/system/

.PHONY: test
test:
	ruby test.rb

.PHONY: clean
clean:
