prefix ?= /usr/local

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/bin
	mkdir -p $(DESTDIR)$(prefix)/share/applications
	mkdir -p $(DESTDIR)/opt/webmenu
	cp -r lib node_modules bin routes docs content nodejs *.js *.coffee *.json *.md $(DESTDIR)/opt/webmenu
	install -o root -g root -m 644 webmenu.desktop \
		$(DESTDIR)$(prefix)/share/applications/webmenu.desktop
	install -o root -g root -m 644 webmenu-spawn.desktop \
		$(DESTDIR)$(prefix)/share/applications/webmenu-spawn.desktop
	install -o root -g root -m 755 bin/start \
		$(DESTDIR)$(prefix)/bin/webmenu
	install -o root -g root -m 755 bin/webmenu-spawn \
		$(DESTDIR)$(prefix)/bin/webmenu-spawn
