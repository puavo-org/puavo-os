
prefix ?= /usr/local

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/bin
	install -o root -g root -m 755 server.rb \
		$(DESTDIR)$(prefix)/bin/logrelay
	mkdir -p $(DESTDIR)/etc
	install -o root -g root -m 644 config.rb-dist \
		$(DESTDIR)/etc/logrelay.rb
