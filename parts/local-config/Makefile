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
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-local-config/templates/etc
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d
	mkdir -p $(DESTDIR)$(libdir)/puavo-local-config-ui
	mkdir -p $(DESTDIR)$(libdir)/puavo-local-config/pam
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-local-config-ui
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-local-config
	
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		puavo-local-config-ui.desktop
	
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-local-config/templates/etc \
		templates/etc/cpufreqd.conf
	
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d \
		init-puavo.d/*-*
	
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-local-config-ui \
		plc-ui/index.html   \
		plc-ui/index.js     \
		plc-ui/package.json \
		plc-ui/style.css    \
		plc-ui/theme.css
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-local-config/pam \
		pam/login-setup
	
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-local-config-ui-autostart.desktop

.PHONY : clean
clean :

.PHONY : deb
deb :
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)
	dpkg-buildpackage -us -uc
