prefix ?= /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

build: npm-install
	node_modules/.bin/grunt

# Build node-webkit package
# https://github.com/rogerwang/node-webkit/wiki/How-to-package-and-distribute-your-apps
nw: build
	zip -r ../webmenu-`git rev-parse HEAD`.nw *

clean-nw:
	rm -r ../webmenu-*.nw

npm-install:
	npm install

clean:
	npm clean
	rm -rf node_modules
	rm -rf out

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)/etc/xdg/autostart
	mkdir -p $(DESTDIR)/opt/webmenu

install: install-dirs
	cp -r lib node_modules bin docs scripts vendor theme styles *.js *.coffee *.json *.md *.html $(DESTDIR)/opt/webmenu
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart \
		webmenu.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		webmenu-spawn.desktop
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/webmenu \
		bin/webmenu-spawn

uninstall:
	rm $(DESTDIR)$(bindir)/webmenu-spawn
	rm $(DESTDIR)$(bindir)/webmenu
	rm -rf $(DESTDIR)/opt/webmenu
	rm $(DESTDIR)$(datarootdir)/applications/webmenu-spawn.desktop 
	rm $(DESTDIR)/etc/xdg/autostart/webmenu.desktop

test-client:
	grunt mocha

test-node:
	node_modules/.bin/mocha --reporter spec --compilers coffee:coffee-script tests/*test*

test: test-client test-node
