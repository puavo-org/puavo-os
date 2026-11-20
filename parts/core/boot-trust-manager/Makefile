prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

RELEASE_DIRECTORY = target/release
BIN = $(RELEASE_DIRECTORY)/puavo-boot-trust-manager

.PHONY: all
all: build

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)/usr/sbin/

# Build releases from scratch every time.
.PHONY: build
build:
	rm -rf $(RELEASE_DIRECTORY)
	cargo build --release

.PHONY: debug
debug:
	cargo build

.PHONY: install
install: $(BIN) install-directories
	cp $(BIN) $(DESTDIR)/usr/sbin/

# Captures the boots the tests compare against. Needs QEMU and swtpm.
.PHONY: captures
captures:
	sh tests/scripts/refresh-captures

.PHONY: format
format:
	cargo fmt

.PHONY: clean
clean:
	rm -rf target
