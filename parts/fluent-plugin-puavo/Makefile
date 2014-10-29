prefix = /usr/local

.PHONY: all
all:
	bundle install --deployment

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)/usr/lib/ruby/vendor_ruby/fluent/plugin

.PHONY: install
install: install-dirs
	cp -a out_puavo.rb $(DESTDIR)/usr/lib/ruby/vendor_ruby/fluent/plugin

.PHONY: test
test:
	bundle exec ruby1.9.1 test/out_puavo_test.rb

.PHONY: clean
clean:
