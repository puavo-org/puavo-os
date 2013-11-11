prefix = /usr/local

all:

install-dirs:
	mkdir -p $(DESTDIR)/usr/lib/fluent/ruby/lib/ruby/vendor_ruby/fluent/plugin

install: install-dirs
	cp -a out_puavo.rb $(DESTDIR)/usr/lib/fluent/ruby/lib/ruby/vendor_ruby/fluent/plugin

clean:
