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
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d
	mkdir -p $(DESTDIR)$(libdir)/puavo-local-config-ui

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-local-config-ui
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-local-config
	
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d \
		init-puavo.d/*-*
	
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-local-config-ui \
		app/index.html   \
		app/index.js     \
		app/package.json \
		app/style.css

.PHONY : clean
clean :
