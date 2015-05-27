prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) puavo-pkg

.PHONY : clean
clean :
