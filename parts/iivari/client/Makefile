prefix ?= /usr

all:

install:
	for bin in iivari-display_off \
		   iivari-display_on \
		   iivari-kiosk; do \
	  install -D -o root -g root -m 755 bin/$$bin \
		  $(DESTDIR)$(prefix)/bin/$$bin; \
	done
	mkdir -p $(DESTDIR)$(prefix)/share/pyshared
	cp -Ru iivari $(DESTDIR)$(prefix)/share/pyshared/iivari/

clean:
