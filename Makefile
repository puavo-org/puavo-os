
prefix ?= /usr/local

build:
	npm install

install-dirs:
	mkdir -p $(DESTDIR)/opt/puavo-logrelay
	mkdir -p $(DESTDIR)/etc

install: install-dirs
	cp -r package.json node_modules/ lib/ $(DESTDIR)/opt/puavo-logrelay
	install -m 644 config.json $(DESTDIR)/etc/puavo-logrelay.json


