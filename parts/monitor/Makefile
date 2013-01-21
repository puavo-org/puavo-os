
prefix ?= /usr/local

build:
	npm install

install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/lib/node_modules/puavo-monitor
	mkdir -p $(DESTDIR)/etc
	mkdir -p $(DESTDIR)$(prefix)/bin
	mkdir -p $(DESTDIR)/var/run

install: install-dirs
	cp -r package.json node_modules/ lib/ bin/ $(DESTDIR)$(prefix)/lib/node_modules/puavo-monitor
	install -m 644 config.json $(DESTDIR)/etc/puavo-monitor.json
	ln -fs ../lib/node_modules/puavo-monitor/bin/puavo-monitor $(DESTDIR)$(prefix)/bin/puavo-monitor
	touch $(DESTDIR)/var/run/puavo-monitor.pid
	chown nobody $(DESTDIR)/var/run/puavo-monitor.pid

