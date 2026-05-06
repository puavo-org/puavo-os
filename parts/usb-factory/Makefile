prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

ifeq ($(prefix), /usr/local)
sysconfdir = $(prefix)/etc
else
sysconfdir = /etc
endif

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 0644

FLASHDRIVE_IMAGES = flash-drive-blue.png    \
                    flash-drive-green.png   \
                    flash-drive-grey.png    \
                    flash-drive-magenta.png \
                    flash-drive-red.png     \
                    flash-drive-yellow.png  \
                    flash-drive-white.png

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-usb-factory
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-usb-factory
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-usb-factory \
		${FLASHDRIVE_IMAGES}
	$(INSTALL) -m 440 -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-usb-factory

.PHONY: downscale-images
downscale-images:
	for image in ${FLASHDRIVE_IMAGES}; do \
	    convert -resize x68 big_images/$${image} $${image}; \
	done

.PHONY: clean
clean:
