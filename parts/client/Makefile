prefix ?= /usr

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/sbin
	install -o root -g root -m 755 install-puavodevice \
	  $(DESTDIR)$(prefix)/sbin/install-puavodevice

clean:
