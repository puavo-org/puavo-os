prefix = /usr/local
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

all: create_monitors_xml

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client

create_monitors_xml: create_monitors_xml.c
	cc -o $@ $< `pkg-config --cflags --libs gnome-desktop-3.0`

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client \
		create_monitors_xml

clean:
	rm -f create_monitors_xml
