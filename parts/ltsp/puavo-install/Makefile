prefix = /usr/local
exec_prefix = $(prefix)
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
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/screen.d
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/init

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-install \
		puavo-install-and-update-ltspimages \
		puavo-install-grub \
		puavo-setup-filesystems \
		puavo-update-thishost

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/ltsp/screen.d \
                screen.d/ltspimage-update

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/init \
		upstart/puavo-update-thishost.conf

.PHONY : clean
clean :
