# Builds the recovery environment as an unsigned UKI with Buildroot.

BUILDROOT_VERSION = 2026.02.3
BUILDROOT_SHA256 = 5a59e7501b0b4ec52c41f4bfa79412320e0b37eae5f719605a258e8d0c6fc7fb
BUILDROOT_SITE = https://buildroot.org/downloads
BUILDROOT_FILE = buildroot-$(BUILDROOT_VERSION).tar.xz
BUILDROOT_ARCHIVE = downloads/$(BUILDROOT_FILE)
BUILDROOT_DIRECTORY = build/buildroot-$(BUILDROOT_VERSION)
# Changes to Buildroot itself, such as the versions of packages that must
# match those of the images.
BUILDROOT_PATCHES = $(sort $(wildcard board/buildroot-patches/*.patch))
OUTPUT_DIRECTORY = $(CURDIR)/build/output
OVERLAY_DIRECTORY = $(CURDIR)/build/overlay

INTERFACE_DIRECTORY = ../interface
INTERFACE_PROGRAM = recovery-interface
# Cargo features of the interface. A development build talks to the address
# of the build without checking its certificate, a debug build has a root
# shell on the second console. Each marks every screen and gets a UKI name
# of its own.
INTERFACE_FEATURES =
INTERFACE_TARGET = x86_64-unknown-linux-musl
INTERFACE_TARGET_DIRECTORY = $(CURDIR)/build/interface
INTERFACE_RELEASE_DIRECTORY = \
	$(INTERFACE_TARGET_DIRECTORY)/$(INTERFACE_TARGET)/release
INTERFACE_BINARY = $(INTERFACE_RELEASE_DIRECTORY)/$(INTERFACE_PROGRAM)
# The addresses of the support sites, separated by spaces. The interface
# shows them at the code entry.
RECOVERY_SUPPORT_ADDRESSES = https://tuki.opinsys.fi
# The C compiler for the few C and assembly files of the TLS cryptography.
# They call nothing of the C library that musl lacks.
INTERFACE_C_COMPILER = gcc
# The certificate authorities that may certify the recovery service, as a
# PEM file, and the address of the service.
# A product build trusts only these authorities. The PCR public keys of the
# images are those the image enrollments use, each named as in the image.
RECOVERY_AUTHORITIES =
RECOVERY_ADDRESS =
RECOVERY_PCR_PUBLIC_KEYS =
# The Secure Boot directory of an image, whose database a full reset writes
# to the firmware with the device keys.
RECOVERY_SECURE_BOOT_DIRECTORY =
CONFIGURATION_DIRECTORY = etc/puavo-recovery
PCR_PUBLIC_KEY_DIRECTORY = etc/puavo-conf
SECURE_BOOT_DIRECTORY = etc/puavo-secure-boot
# systemd sets a clock that is earlier than the time of this file to that
# time, so a device with a dead clock battery starts at the build date and
# accepts certificates issued before it.
CLOCK_EPOCH = usr/lib/clock-epoch

# Crates download into the build tree, not the home directory.
CARGO_DIRECTORY = $(CURDIR)/build/cargo

KERNEL_IMAGE = $(OUTPUT_DIRECTORY)/images/bzImage
ROOT_FILESYSTEM = $(OUTPUT_DIRECTORY)/images/rootfs.cpio.zst
UKI_SUFFIX = $(foreach feature,$(INTERFACE_FEATURES),-$(feature))
UKI = build/recovery$(UKI_SUFFIX).efi
DEBUG_SHELL_OPTION = systemd.debug_shell=/dev/tty2
# The start does not wait for the TPM, which only the repair uses.
COMMAND_LINE = quiet loglevel=3 fbcon=font:TER16x32 lockdown=confidentiality \
	systemd.tpm2_wait=false \
	$(if $(filter debug,$(INTERFACE_FEATURES)),$(DEBUG_SHELL_OPTION))

.PHONY: all
all: $(UKI)

$(BUILDROOT_ARCHIVE):
	mkdir --parents downloads
	curl --silent --show-error --fail --location --output $@.tmp \
		$(BUILDROOT_SITE)/$(BUILDROOT_FILE)
	echo '$(BUILDROOT_SHA256)  $@.tmp' | sha256sum --check --quiet
	mv $@.tmp $@

# The tree is unpacked again when a patch changes, so each applies once.
$(BUILDROOT_DIRECTORY): $(BUILDROOT_ARCHIVE) $(BUILDROOT_PATCHES)
	rm --recursive --force $@
	mkdir --parents build
	tar --extract --file $< --directory build
	for patch in $(BUILDROOT_PATCHES); do \
		patch --strip=1 --directory=$@ --input=$(CURDIR)/$$patch \
			|| exit 1; \
	done
	touch $@

# The interface is static, so it needs nothing from the Buildroot C library.
.PHONY: interface
interface:
	cd $(INTERFACE_DIRECTORY) && \
		CARGO_HOME=$(CARGO_DIRECTORY) \
		CARGO_TARGET_DIR=$(INTERFACE_TARGET_DIRECTORY) \
		RECOVERY_SUPPORT_ADDRESSES='$(RECOVERY_SUPPORT_ADDRESSES)' \
		CC_x86_64_unknown_linux_musl=$(INTERFACE_C_COMPILER) \
		cargo build --locked --release --target $(INTERFACE_TARGET) \
		--package $(INTERFACE_PROGRAM) --features '$(INTERFACE_FEATURES)'
	install -D $(INTERFACE_BINARY) \
		$(OVERLAY_DIRECTORY)/usr/bin/$(INTERFACE_PROGRAM)

# Writes the configuration of the build into the overlay.
.PHONY: configuration
configuration:
	# Every build needs the address of the service, and the PCR public keys
	# and the Secure Boot directory for the repair. A product build needs the
	# authorities, since it trusts no others.
	$(if $(RECOVERY_ADDRESS),,$(error RECOVERY_ADDRESS is not set))
	$(if $(RECOVERY_PCR_PUBLIC_KEYS),,$(error RECOVERY_PCR_PUBLIC_KEYS is not set))
	$(if $(RECOVERY_SECURE_BOOT_DIRECTORY),,\
		$(error RECOVERY_SECURE_BOOT_DIRECTORY is not set))
	$(if $(or $(RECOVERY_AUTHORITIES),$(filter development,$(INTERFACE_FEATURES))),,\
		$(error RECOVERY_AUTHORITIES is not set))

	# The target directory keeps the files of earlier builds, so the
	# configuration is removed there too.
	rm --recursive --force $(OVERLAY_DIRECTORY)/$(CONFIGURATION_DIRECTORY) \
		$(OUTPUT_DIRECTORY)/target/$(CONFIGURATION_DIRECTORY) \
		$(OVERLAY_DIRECTORY)/$(PCR_PUBLIC_KEY_DIRECTORY) \
		$(OUTPUT_DIRECTORY)/target/$(PCR_PUBLIC_KEY_DIRECTORY) \
		$(OVERLAY_DIRECTORY)/$(SECURE_BOOT_DIRECTORY) \
		$(OUTPUT_DIRECTORY)/target/$(SECURE_BOOT_DIRECTORY)
	mkdir --parents $(OVERLAY_DIRECTORY)/$(CONFIGURATION_DIRECTORY) \
		$(OVERLAY_DIRECTORY)/$(PCR_PUBLIC_KEY_DIRECTORY)

	# The recovery service.
	$(if $(RECOVERY_AUTHORITIES),install --mode=0644 \
		$(RECOVERY_AUTHORITIES) \
		$(OVERLAY_DIRECTORY)/$(CONFIGURATION_DIRECTORY)/authorities.pem)
	echo '$(RECOVERY_ADDRESS)' \
		> $(OVERLAY_DIRECTORY)/$(CONFIGURATION_DIRECTORY)/address

	# What the repair enrolls and writes to the firmware.
	install --mode=0644 $(RECOVERY_PCR_PUBLIC_KEYS) \
		$(OVERLAY_DIRECTORY)/$(PCR_PUBLIC_KEY_DIRECTORY)
	cp --recursive $(RECOVERY_SECURE_BOOT_DIRECTORY)/. \
		$(OVERLAY_DIRECTORY)/$(SECURE_BOOT_DIRECTORY)

	# The clock starts no earlier than the build.
	mkdir --parents $(dir $(OVERLAY_DIRECTORY)/$(CLOCK_EPOCH))
	touch $(OVERLAY_DIRECTORY)/$(CLOCK_EPOCH)

# lvm2 waits for udev, udev comes with systemd, systemd needs cryptsetup,
# and cryptsetup needs lvm2. So a build without udev first makes systemd
# with an lvm2 that does not wait, and lvm2 is built again after it.
LIBUDEV = $(OUTPUT_DIRECTORY)/staging/usr/lib/pkgconfig/libudev.pc

.PHONY: root-filesystem
root-filesystem: $(BUILDROOT_DIRECTORY) interface configuration
	$(MAKE) --directory=$(BUILDROOT_DIRECTORY) O=$(OUTPUT_DIRECTORY) \
		BR2_EXTERNAL=$(CURDIR) puavo_recovery_defconfig
	if [ ! -e $(LIBUDEV) ]; then \
		$(MAKE) --directory=$(BUILDROOT_DIRECTORY) \
			O=$(OUTPUT_DIRECTORY) PUAVO_RECOVERY_LVM2_UDEV=no systemd \
		&& $(MAKE) --directory=$(BUILDROOT_DIRECTORY) \
			O=$(OUTPUT_DIRECTORY) lvm2-dirclean; \
	fi
	$(MAKE) --directory=$(BUILDROOT_DIRECTORY) O=$(OUTPUT_DIRECTORY) \
		puavo-boot-trust-manager-rebuild
	$(MAKE) --directory=$(BUILDROOT_DIRECTORY) O=$(OUTPUT_DIRECTORY)

$(UKI): root-filesystem
	ukify build --linux=$(KERNEL_IMAGE) --initrd=$(ROOT_FILESYSTEM) \
		--cmdline='$(COMMAND_LINE)' --output=$@

.PHONY: clean
clean:
	rm --recursive --force build
