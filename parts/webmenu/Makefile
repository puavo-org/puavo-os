

prefix ?= /usr/local

all:
	echo noop

install:
	mkdir -p $(DESTDIR)$(prefix)/bin
	mkdir -p /opt/webmenu
	install -o root -g root -m 755 bin/webmenu \
		$(DESTDIR)$(prefix)/bin/webmenu
