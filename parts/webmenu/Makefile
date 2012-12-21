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
	rm -f styles/main.css
	rm -rf node_modules
	rm -rf out

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)/etc/xdg/autostart
	mkdir -p $(DESTDIR)/opt/webmenu
	mkdir -p $(DESTDIR)/usr/share/icons

install: install-dirs
	cp -r lib node_modules bin docs scripts vendor styles *.js *.json *.md *.html $(DESTDIR)/opt/webmenu
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart \
		extra/webmenu.desktop
	$(INSTALL_DATA) -t $(DESTDIR)/usr/share/icons \
		extra/icons/webmenu.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		extra/webmenu-spawn.desktop
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/webmenu \
		bin/webmenu-spawn

uninstall:
	rm $(DESTDIR)$(bindir)/webmenu-spawn
	rm $(DESTDIR)$(bindir)/webmenu
	rm -rf $(DESTDIR)/opt/webmenu
	rm $(DESTDIR)$(datarootdir)/applications/webmenu-spawn.desktop 
	rm $(DESTDIR)/etc/xdg/autostart/webmenu.desktop
	rm $(DESTDIR)/usr/share/icons/webmenu.png

test-client:
	node_modules/.bin/grunt mocha

test-nw:
	test=1 nw .

test-nw-hidden:
	test=1 exit=1 nw .

test-node:
	node_modules/.bin/mocha --reporter spec --compilers coffee:coffee-script tests/*test*

test: test-client test-node

serve:
	@echo View tests on http://localhost:3000/tests.html
	node_modules/.bin/serve --no-stylus  --no-jade --port 3000 .

watch:
	node watchers.js
