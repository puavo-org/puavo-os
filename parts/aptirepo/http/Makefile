prefix = /usr/local

all:

install-dirs:
	mkdir -p \
		$(DESTDIR)/etc/aptirepo \
		$(DESTDIR)$(prefix)/lib/aptirepo-http

install: install-dirs
	cp -a \
		server.py \
		templates \
		$(DESTDIR)$(prefix)/lib/aptirepo-http
	cp -a \
		distributions \
		http.conf \
		$(DESTDIR)/etc/aptirepo

clean:
