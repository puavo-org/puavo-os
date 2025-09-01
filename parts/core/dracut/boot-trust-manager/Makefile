prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all: build

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)/usr/sbin/

.PHONY: build
build: target/release/puavo-boot-trust-manager

target/release/puavo-boot-trust-manager: Cargo.toml
	cargo build --release

.PHONY: install
install: build install-directories
	cp target/release/puavo-boot-trust-manager $(DESTDIR)/usr/sbin/

.PHONY: clean
clean:
	rm -rf target
