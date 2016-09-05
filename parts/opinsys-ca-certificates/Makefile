prefix ?= /usr

.PHONY: all
all:

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(prefix)/share/ca-certificates/opinsys \
		 $(DESTDIR)/etc/ssl/certs
	install -o root -g root -m 644 ca-certificates/opinsys-ca.crt \
	  $(DESTDIR)$(prefix)/share/ca-certificates/opinsys/opinsys-ca.crt
	ln -fs opinsys-ca.crt $(DESTDIR)/etc/ssl/certs/33bd8bf8.0
	ln -fs /usr/share/ca-certificates/opinsys/opinsys-ca.crt \
	       $(DESTDIR)/etc/ssl/certs/opinsys-ca.crt
