prefix ?= /usr/local

.PHONY: all
all:
	npm install --registry http://registry.npmjs.org

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/lib/node_modules/puavo-monitor
	mkdir -p $(DESTDIR)/etc
	mkdir -p $(DESTDIR)$(prefix)/bin

.PHONY: install
install: install-dirs
	cp -r package.json node_modules/ lib/ bin/ $(DESTDIR)$(prefix)/lib/node_modules/puavo-monitor
	install -m 644 config.json $(DESTDIR)/etc/puavo-monitor.json
	ln -fs ../lib/node_modules/puavo-monitor/bin/puavo-monitor $(DESTDIR)$(prefix)/bin/puavo-monitor

.PHONY: clean
clean:
