prefix ?= /usr/local
sysconfdir ?= $(prefix)/etc

.PHONY: build
build:
	@echo :\)

.PHONY: test
test:
	ruby1.9.3 test/run.rb

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/sbin
	mkdir -p $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/puavo-tftp

.PHONY: install
install: install-dirs
	install -o root -g root -m 755 puavo-tftpd \
	  $(DESTDIR)$(prefix)/sbin/puavo-tftpd
	install -o root -g root -m 755 puavo-tftp/* $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/puavo-tftp
	install -o root -g root -m 755 puavo-tftp.yml $(sysconfdir)/puavo-tftp.yml