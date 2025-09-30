prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

BIN = target/release/puavo-boot-trust-manager
SOURCE_FILES = $(shell find src -type f -name '*.rs')

.PHONY: all
all: build

.PHONY: install-directories
install-directories:
	mkdir -p $(DESTDIR)/usr/sbin/

.PHONY: build
build: $(BIN)

$(BIN): Cargo.lock Cargo.toml $(SOURCE_FILES)
	cargo build --release

.PHONY: install
install: build install-directories
	cp $(BIN) $(DESTDIR)/usr/sbin/

.PHONY: clean
clean:
	rm -rf target
