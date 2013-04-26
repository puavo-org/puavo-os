prefix ?= /usr/local
NW ?= nw
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

# node-webkit version
NW_VERSION=0.4.1
# https://github.com/rogerwang/nw-gyp
NW_GYP=$(CURDIR)/node_modules/.bin/nw-gyp
define nw-build
	@echo "Building node.js module '$1' for node-webkit"
	cd node_modules/$1/ && $(NW_GYP) configure --target=$(NW_VERSION) && $(NW_GYP) build
endef


build: npm-install grunt r.js i18n

# Build node-webkit package
# https://github.com/rogerwang/node-webkit/wiki/How-to-package-and-distribute-your-apps
nw: build
	zip -r ../webmenu-`git rev-parse HEAD`.nw *

clean-nw:
	rm -r ../webmenu-*.nw

nw-gyp:
	$(call nw-build,ffi/node_modules/ref)
	$(call nw-build,ffi)
	$(call nw-build,posix)

npm-install:
	npm install
	make nw-gyp

r.js:
	node_modules/.bin/r.js -o mainConfigFile=scripts/config.js name=start out=scripts/bundle.js

grunt:
	node_modules/.bin/grunt

clean:
	rm -f styles/main.css
	rm -rf node_modules
	rm -rf out
	rm -rf build/
	rm -rf i18n/*/i18n.js
	rm -rf scripts/bundle.js

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)/etc/xdg/autostart
	mkdir -p $(DESTDIR)/opt/webmenu/extra/icons/apps/
	mkdir -p $(DESTDIR)/usr/share/icons
	mkdir -p $(DESTDIR)/etc/webmenu

install: install-dirs
	cp -r lib node_modules bin docs scripts vendor styles extra i18n *.js *.json *.md *.html $(DESTDIR)/opt/webmenu
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart \
		extra/webmenu.desktop
	$(INSTALL_DATA) -t $(DESTDIR)/usr/share/icons \
		extra/icons/webmenu.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		extra/webmenu-spawn.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		extra/webmenu-spawn-logout.desktop
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
	test=1 $(NW) .

test-nw-hidden:
	test=1 exit=1 $(NW) .

test-node:
	node_modules/.bin/mocha --reporter spec --compilers coffee:coffee-script tests/*test*

test: test-client test-node

serve:
	@echo View tests on http://localhost:3000/tests.html
	node_modules/.bin/serve --no-stylus  --no-jade --port 3000 .

.PHONY : i18n
i18n:
	@node_modules/.bin/coffee extra/bin/i18n-update

watch:
	node extra/bin/watchers.js
