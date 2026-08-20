TARGET = x86_64-unknown-uefi
BIN = target/$(TARGET)/release/slab.efi
SOURCE_FILES = $(shell find src -type f -name '*.rs')
VERIFIER_KEYS = $(abspath authorities)
INSTALL_DIR = $(DESTDIR)/usr/lib/slab
SBIN_DIR = $(DESTDIR)/usr/sbin

.PHONY: all
all: build

.PHONY: build
build: $(BIN)

# We need to compile the core and alloc for the UEFI target with rust-src,
# because Debian does not ship the target libraries and rustup conflicts
# with the cargo package, which is required by other components.
# UEFI requires lld-link as linker, which Debian ships in the lld package,
# rather than bundled with rustc.
$(BIN): Cargo.lock Cargo.toml build.rs $(SOURCE_FILES)
	RUSTC_BOOTSTRAP=1 RUSTFLAGS='-C linker=lld-link' \
	  SLAB_VERIFIER_KEYS='$(VERIFIER_KEYS)' \
	  cargo build --release --target $(TARGET) \
	  -Z build-std=core,alloc --bin slab --features verifier

# Installs the unsigned slab and utilities.
.PHONY: install
install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BIN) $(INSTALL_DIR)/slabx64.efi
	sed -n 's/^version = "\(.*\)"$$/\1/p' Cargo.toml \
	  > $(INSTALL_DIR)/version
	mkdir -p $(SBIN_DIR)
	install -m 755 tools/slab-info tools/slab-debug $(SBIN_DIR)/
	install -m 755 tools/slab-reset $(INSTALL_DIR)/

# Debug slab binary for the QEMU test harnesses.
.PHONY: test-binary
test-binary:
	cargo build --target $(TARGET) --bin slab

# Runs every test harness.
.PHONY: test
test: test-binary
	sh tests/test.sh

.PHONY: format
format:
	cargo fmt

.PHONY: clean
clean:
	rm -rf target
