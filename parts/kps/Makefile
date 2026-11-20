prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin

ifeq ($(prefix), /usr/local)
sysconfdir = $(prefix)/etc
else
sysconfdir = /etc
endif

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

RELEASE_DIRECTORY = target/release
DAEMON_BIN = $(RELEASE_DIRECTORY)/puavo-kpsd
CLIENT_BIN = $(RELEASE_DIRECTORY)/puavo-kps
BINS = $(DAEMON_BIN) $(CLIENT_BIN)

.PHONY: all
all: build

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)$(bindir)/
	mkdir -p $(DESTDIR)$(sbindir)/
	mkdir -p $(DESTDIR)$(prefix)/lib/systemd/system/
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-kps/

# Build releases from scratch every time.
.PHONY: build
build:
	rm -rf $(RELEASE_DIRECTORY)
	cargo build --release

.PHONY: debug
debug:
	cargo build

.PHONY: install
install: $(BINS) install-directories
	$(INSTALL_PROGRAM) $(DAEMON_BIN) $(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) $(CLIENT_BIN) $(DESTDIR)$(bindir)/
	$(INSTALL_DATA) etc/puavo-kps/config.toml \
		$(DESTDIR)$(sysconfdir)/puavo-kps/config.toml
	$(INSTALL_DATA) systemd/puavo-kpsd.service \
		$(DESTDIR)$(prefix)/lib/systemd/system/

.PHONY: test
test:
	cargo test

.PHONY: clean
clean:
	rm -rf target
