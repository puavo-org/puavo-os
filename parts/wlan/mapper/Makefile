prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all: horst

horst:
	make -C horst
	cp horst/horst puavo-wlanmapper-horst

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: horst installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanmapper \
		puavo-wlanmapper-horst

clean:
	make -C horst clean
	rm -f puavo-wlanmapper-horst

.PHONY: all	    \
	clean	    \
	horst	    \
	install	    \
	installdirs
