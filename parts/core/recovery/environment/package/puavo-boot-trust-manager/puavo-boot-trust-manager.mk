################################################################################
#
# puavo-boot-trust-manager
#
################################################################################

# Built from the tree with the cargo of the build host, linked against the
# libraries of the environment.
PUAVO_BOOT_TRUST_MANAGER_SITE = $(BR2_EXTERNAL_PUAVO_RECOVERY_PATH)/../../boot-trust-manager
PUAVO_BOOT_TRUST_MANAGER_SITE_METHOD = local
PUAVO_BOOT_TRUST_MANAGER_OVERRIDE_SRCDIR_RSYNC_EXCLUSIONS = --exclude target
PUAVO_BOOT_TRUST_MANAGER_DEPENDENCIES = cryptsetup host-pkgconf systemd tpm2-tss

PUAVO_BOOT_TRUST_MANAGER_TARGET = x86_64-unknown-linux-gnu
PUAVO_BOOT_TRUST_MANAGER_BINARY = \
	$(@D)/target/$(PUAVO_BOOT_TRUST_MANAGER_TARGET)/release/puavo-boot-trust-manager
# The enrollments and quirks the images ship in their initrd.
PUAVO_BOOT_TRUST_MANAGER_CONFIGURATORS = \
	$(BR2_EXTERNAL_PUAVO_RECOVERY_PATH)/../../dracut/modules.d/80puavo-boot-trust-manager/configurators/primary
# The scripts a full reset runs, as the initrd of the images has them.
PUAVO_BOOT_TRUST_MANAGER_SCRIPT_SOURCE = \
	$(BR2_EXTERNAL_PUAVO_RECOVERY_PATH)/../../../ltsp/puavo-install/lib
PUAVO_BOOT_TRUST_MANAGER_SCRIPT_DIRECTORY = /usr/lib/puavo-ltsp-install
PUAVO_BOOT_TRUST_MANAGER_SCRIPTS = puavo-create-device-tpm-keys \
	puavo-prepare-secure-boot puavo-reset-tpm puavo-setup-secure-boot \
	puavo-update-device-db

PUAVO_BOOT_TRUST_MANAGER_BUILD_ENV = \
	CARGO_HOME=$(BR2_EXTERNAL_PUAVO_RECOVERY_PATH)/build/cargo \
	CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=$(TARGET_CC) \
	CC_x86_64_unknown_linux_gnu=$(TARGET_CC) \
	PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) \
	PKG_CONFIG_ALLOW_CROSS=1 \
	BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$(STAGING_DIR)"

define PUAVO_BOOT_TRUST_MANAGER_BUILD_CMDS
	cd $(@D) && $(PUAVO_BOOT_TRUST_MANAGER_BUILD_ENV) \
		cargo build --release --locked \
		--target $(PUAVO_BOOT_TRUST_MANAGER_TARGET)
endef

define PUAVO_BOOT_TRUST_MANAGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D --mode=0755 $(PUAVO_BOOT_TRUST_MANAGER_BINARY) \
		$(TARGET_DIR)/usr/sbin/puavo-boot-trust-manager
	mkdir --parents $(TARGET_DIR)/etc/puavo
	cp --recursive $(PUAVO_BOOT_TRUST_MANAGER_CONFIGURATORS)/. \
		$(TARGET_DIR)/etc/puavo
	$(foreach script,$(PUAVO_BOOT_TRUST_MANAGER_SCRIPTS),\
		$(INSTALL) -D --mode=0755 \
			$(PUAVO_BOOT_TRUST_MANAGER_SCRIPT_SOURCE)/$(script) \
			$(TARGET_DIR)$(PUAVO_BOOT_TRUST_MANAGER_SCRIPT_DIRECTORY)/$(script)$(sep))
endef

$(eval $(generic-package))
