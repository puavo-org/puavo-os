prefix ?= /usr/local
sysconfdir ?= $(prefix)/etc

install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/sbin

install: install-dirs
	install -o root -g root -m 755 puavo-ltspboot-config \
	  $(DESTDIR)$(prefix)/sbin/puavo-ltspboot-config
	install -o root -g root -m 755 puavo-tftp.yml $(sysconfdir)/puavo-tftp.yml