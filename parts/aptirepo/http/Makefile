prefix = /usr/local

all:

install-dirs:
	mkdir -p \
		$(DESTDIR)/etc/aptirepo \
		$(DESTDIR)$(prefix)/lib/aptirepo-http

install: install-dirs
	cp -a server.py $(DESTDIR)$(prefix)/lib/aptirepo-http
	cp -a distributions $(DESTDIR)/etc/aptirepo

clean:
