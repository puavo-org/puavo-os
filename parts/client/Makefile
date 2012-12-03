prefix ?= /usr

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/sbin
	install -o root -g root -m 755 puavo-register \
	  $(DESTDIR)$(prefix)/sbin/puavo-register

clean:
