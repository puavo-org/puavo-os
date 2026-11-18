include $(sort $(wildcard $(BR2_EXTERNAL_PUAVO_RECOVERY_PATH)/package/*/*.mk))

# Device mapper waits for udev, as in the initrd of the images, so a
# mapping is known to udev once its activation returns. The first build of
# udev goes without it, see the Makefile.
ifneq ($(PUAVO_RECOVERY_LVM2_UDEV),no)
LVM2_CONF_OPTS += --enable-udev_sync
LVM2_DEPENDENCIES += udev
endif
