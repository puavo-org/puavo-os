prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs/conf.d
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs/hooks
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs/scripts
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs/scripts/init-top
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs/scripts/puavo-postmount

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs/hooks \
                initramfs/hooks/puavo
	$(INSTALL_PROGRAM) \
                -t $(DESTDIR)$(datarootdir)/initramfs/scripts/init-top \
		initramfs/scripts/init-top/puavo
	$(INSTALL_PROGRAM) \
		-t $(DESTDIR)$(datarootdir)/initramfs/scripts/puavo-postmount \
		initramfs/scripts/puavo-postmount/01-mount
	$(INSTALL_PROGRAM) -t $(DESTDIR)/sbin init-puavo

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/initramfs/conf.d \
                initramfs/conf.d/puavo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/initramfs/scripts \
                initramfs/scripts/puavo

.PHONY : clean
clean :
