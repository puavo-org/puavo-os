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

DAEMON_BIN = target/release/puavo-kpsd
CLIENT_BIN = target/release/puavo-kps
BINS = $(DAEMON_BIN) $(CLIENT_BIN)
SOURCE_FILES = $(shell find crates -type f -name '*.rs')

.PHONY: all
all: build

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)$(bindir)/
	mkdir -p $(DESTDIR)$(sbindir)/
	mkdir -p $(DESTDIR)$(prefix)/lib/systemd/system/
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-kps/

.PHONY: build
build: $(BINS)

$(BINS): Cargo.lock Cargo.toml $(SOURCE_FILES)
	cargo build --release

.PHONY: install
install: build install-directories
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
