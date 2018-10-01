INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

appdir = /opt/puavo-wlancontroller
vardir = /var/opt/puavo-wlancontroller

ifeq ($(prefix), /usr/local)
	systemdsystemunitdir='$(prefix)/lib/systemd/system'
else
	systemdsystemunitdir=$(shell pkg-config systemd --variable=systemdsystemunitdir)
endif

all:

install: all installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)	\
		config.ru			\
		permstore.rb			\
		app.rb				\
		tempstore.rb			\
		oui.txt

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/public	\
		public/*

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/routes	\
		routes/*

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/views	\
		views/*

	$(INSTALL_DATA) -D -t '$(DESTDIR)$(systemdsystemunitdir)' \
		systemd/puavo-wlancontroller.service

installdirs:
	mkdir -p $(DESTDIR)$(appdir)
	mkdir -p $(DESTDIR)$(appdir)/public
	mkdir -p $(DESTDIR)$(appdir)/routes
	mkdir -p $(DESTDIR)$(appdir)/views
	mkdir -p $(DESTDIR)$(vardir)

clean:

.PHONY: all clean install installdirs
