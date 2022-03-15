prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sharedir = $(datarootdir)/puavo-devscripts
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: bin/thumb

bin/thumb:
	gcc -s -O2 -Wall -Wextra -Wpedantic -o bin/thumb bin/thumb.c -std=c99 `pkg-config --cflags --libs gnome-desktop-3.0`

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: install
install: bin/thumb installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/adm-x \
		bin/adm-x11vnc \
		bin/adm-xrandr \
		bin/do-debpool-changes \
		bin/dpkg-diff-img \
		bin/makethumbs \
		bin/thumb

.PHONY: clean
clean:
