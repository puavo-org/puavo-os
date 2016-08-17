export PATH := node_modules/.bin:$(PATH)

prefix ?= /usr/local
NW ?= nw
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

export PATH := node_modules/.bin:$(PATH)

# node-webkit version
NW_VERSION=0.8.2
# https://github.com/rogerwang/nw-gyp
NW_GYP=$(CURDIR)/node_modules/.bin/nw-gyp
define nw-build
	@echo "Building node.js module '$1' for node-webkit"
	cd node_modules/$1/ && $(NW_GYP) configure --target=$(NW_VERSION) && $(NW_GYP) build --arch=ia32
endef


build: npm-install nw-gyp assets
	git rev-parse HEAD > GIT_COMMIT

# Build node-webkit package
# https://github.com/rogerwang/node-webkit/wiki/How-to-package-and-distribute-your-apps
nw: build
	zip -r ../webmenu-`git rev-parse HEAD`.nw *

clean-nw:
	rm -r ../webmenu-*.nw

nw-gyp:
	$(call nw-build,fluent-logger/node_modules/msgpack)
	$(call nw-build,ffi/node_modules/ref)
	$(call nw-build,ffi)
	$(call nw-build,posix)
	$(call nw-build,execSync)

npm-install:
	npm install
	# WTF! execSync is as a dependency in package.json but it does not get
	# installed with plain "npm install". Workaround it by installing it manually.
	# XXX: remove this asap
	npm install execSync
	make nw-gyp

assets: i18n browserify browserify-test stylus node-coffee

.PHONY: i18n
i18n:
	coffee extra/i18nUpdate.coffee

browserify:
	browserify -t hbsfy -t coffeeify ./scripts/main.coffee > bundle.js

browserify-watch:
	watchify --debug -v -t hbsfy -t coffeeify ./scripts/main.coffee -o bundle.js

browserify-test:
	browserify --debug -t hbsfy -t coffeeify ./scripts/tests/index.coffee > ./scripts/tests/bundle.js

browserify-test-watch:
	watchify --debug -v -t hbsfy -t coffeeify ./scripts/tests/index.coffee -o ./scripts/tests/bundle.js

stylus:
	stylus --line-numbers --use nib styles/main.styl

stylus-watch:
	stylus --watch --line-numbers --use nib styles/main.styl

node-coffee:
	mkdir -p lib
	coffee --compile --output lib/ src/*.coffee
	cp src/*.js lib/


clean:
	rm -f styles/main.css
	rm -rf node_modules
	rm -rf build/
	rm -rf lib/
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
	cp -r GIT_COMMIT lib node_modules bin docs scripts vendor styles extra i18n *.js *.json *.md *.html $(DESTDIR)/opt/webmenu
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart \
		extra/webmenu.desktop
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart \
		extra/download-user-photo.desktop
	$(INSTALL_DATA) -t $(DESTDIR)/usr/share/icons \
		extra/icons/webmenu.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		extra/webmenu-spawn.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		extra/webmenu-spawn-logout.desktop
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/webmenu \
		bin/webmenu-spawn \
		bin/webmenu-xdg \
		bin/webmenu-env \
		bin/puavo-download-user-photo

uninstall:
	rm $(DESTDIR)$(bindir)/webmenu-spawn
	rm $(DESTDIR)$(bindir)/webmenu
	rm $(DESTDIR)$(bindir)/puavo-download-user-photo
	rm -rf $(DESTDIR)/opt/webmenu
	rm $(DESTDIR)$(datarootdir)/applications/webmenu-spawn.desktop 
	rm $(DESTDIR)/etc/xdg/autostart/webmenu.desktop
	rm $(DESTDIR)/etc/xdg/autostart/download-user-photo.desktop
	rm $(DESTDIR)/usr/share/icons/webmenu.png

test-nw:
	bin/webmenu --test

test-nw-hidden: assets
	$(NW) . --test --exit

test:
	$(NW) . --test --exit

test-node:
	node_modules/.bin/mocha --reporter spec --compilers coffee:coffee-script tests/*test*

serve:
	@echo View tests on http://localhost:3000/tests.html
	node_modules/.bin/serve --no-stylus  --no-jade --port 3000 .
