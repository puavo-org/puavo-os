prefix      = /usr/local
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)

all:

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) update-gtk-bookmarks
