prefix = /usr

libdir = $(prefix)/lib
sysconfdir = /etc

INSTALL = install -p
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:
	bundle install --deployment

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)$(libdir)/ruby/vendor_ruby/fluent/plugin
	mkdir -p $(DESTDIR)$(sysconfdir)/fluent/conf.d

.PHONY: install
install: install-dirs
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/ruby/vendor_ruby/fluent/plugin out_puavo.rb

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/fluent/conf.d fluent-plugin-puavo.conf

.PHONY: test
test:
	bundle exec ruby test/out_puavo_test.rb

.PHONY: clean
clean:
