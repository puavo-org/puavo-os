prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/screen.d

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-install \
		puavo-install-grub \
		puavo-install-ltspimages \
		puavo-setup-filesystems \
		puavo-update-ltspimage

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/ltsp/screen.d \
                screen.d/ltspimage-update

.PHONY : clean
clean :
