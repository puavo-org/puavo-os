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
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap-dnsproxy
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d \
		vtun-up.d/40-enable-dns-capture
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d \
		vtun-down.d/40-disable-dns-capture

.PHONY : clean
clean :
