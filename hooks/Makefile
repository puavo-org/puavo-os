prefix ?= /usr/local
sysconfdir ?= $(prefix)/etc

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/sbin
	mkdir -p $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby

.PHONY: install
install: install-dirs
	install -o root -g root -m 755 puavo-ltspboot-config \
	  $(DESTDIR)$(prefix)/sbin/puavo-ltspboot-config
	install -o root -g root -m 755 puavo-lts-config \
	  $(DESTDIR)$(prefix)/sbin/puavo-lts-config
	install -o root -g root -m 755 puavo-tftp.yml $(sysconfdir)/puavo-tftp.yml
	install -o root -g root -m 755 puavo-ldap.rb $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby
