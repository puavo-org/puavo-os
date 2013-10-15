prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-dch \
		bin/puavo-deb-release \
		bin/puavo-cp-debian-directory \
		bin/puavo-install-deps \
		bin/mkpkg \
		bin/mktar \
		bin/dpkg-diff-img

clean:
