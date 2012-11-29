prefix ?= /usr

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/share/ca-certificates/opinsys
	install -o root -g root -m 644 ca-certificates/opinsys-ca.crt \
	  $(DESTDIR)$(prefix)/share/ca-certificates/opinsys/opinsys-ca.crt
