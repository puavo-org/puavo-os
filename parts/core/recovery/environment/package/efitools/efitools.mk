################################################################################
#
# efitools
#
################################################################################

EFITOOLS_VERSION = 1.9.2
EFITOOLS_SITE = https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git/snapshot
EFITOOLS_LICENSE = GPL-2.0
EFITOOLS_LICENSE_FILES = COPYING
EFITOOLS_DEPENDENCIES = gnu-efi openssl

# Only the programs the Secure Boot scripts of the images run.
EFITOOLS_PROGRAMS = cert-to-efi-sig-list sign-efi-sig-list efi-readvar \
	efi-updatevar
EFITOOLS_INCLUDES = -I$(@D)/include/ -I$(STAGING_DIR)/usr/include/efi \
	-I$(STAGING_DIR)/usr/include/efi/x86_64 \
	-I$(STAGING_DIR)/usr/include/efi/protocol

# The time parsing of the signing program needs the GNU declarations.
EFITOOLS_CPPFLAGS = -DCONFIG_x86_64 -D_GNU_SOURCE

define EFITOOLS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) --directory=$(@D) CC="$(TARGET_CC)" \
		INCDIR="$(EFITOOLS_INCLUDES)" CPPFLAGS="$(EFITOOLS_CPPFLAGS)" \
		$(EFITOOLS_PROGRAMS)
endef

define EFITOOLS_INSTALL_TARGET_CMDS
	$(foreach program,$(EFITOOLS_PROGRAMS),\
		$(INSTALL) -D --mode=0755 $(@D)/$(program) \
			$(TARGET_DIR)/usr/bin/$(program)$(sep))
endef

$(eval $(generic-package))
