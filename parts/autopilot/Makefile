prefix = /usr

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
libdir = $(prefix)/lib
sysconfdir = /etc

INSTALL = install -p
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

bin/puavo-autopilot-env: Makefile
	echo "#!/bin/sh" > $@
	echo "export PUAVO_AUTOPILOT_SHAREDIR=$(datarootdir)/puavo-autopilot" >> $@
	echo "export PUAVO_AUTOPILOT_LIBDIR=$(libdir)/puavo-autopilot" >> $@

install: bin/puavo-autopilot-env installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d \
		I99-lightdm-puavo-autopilot-login

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-autopilot-session.desktop

	$(INSTALL) -t $(DESTDIR)$(bindir) \
		bin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-autopilot \
		lib/*

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-autopilot \
		share/*.png

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/parameters \
		share/puavo-conf/parameters/puavo-autopilot.json

	rm -f bin/puavo-autopilot-env

installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-autopilot
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/parameters
	mkdir -p $(DESTDIR)$(libdir)/puavo-autopilot
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: all			\
        bin/puavo-autopilot-env \
	install			\
	installdirs
