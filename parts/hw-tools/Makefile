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
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/parameters
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-hw-tools/
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/init

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir)/ \
		bin/probook_ec.pl \
		bin/hpfancontrol

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/init \
		upstart/hpfancontrol.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/parameters \
		share/puavo-conf/parameters/puavo-hw-tools.json

.PHONY : clean
clean :
