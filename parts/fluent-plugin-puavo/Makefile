prefix = /usr/local

all:
	bundle install --deployment

install-dirs:
	mkdir -p $(DESTDIR)/usr/lib/ruby/vendor_ruby/fluent/plugin

install: install-dirs
	cp -a out_puavo.rb $(DESTDIR)/usr/lib/ruby/vendor_ruby/fluent/plugin

.PHONY: test
test:
	bundle exec ruby1.9.1 test/out_puavo_test.rb

clean:
