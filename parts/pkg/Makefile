prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir=/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-pkg

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-pkg

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-pkg \
		config

.PHONY : clean
clean :

.PHONY : install-deb-deps
install-deb-debs:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

.PHONY : install-deb
deb:
	dpkg-buildpackage -us -uc
