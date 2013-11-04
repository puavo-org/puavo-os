prefix = /usr/local

build:
	npm install --registry http://registry.npmjs.org

install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/lib/node_modules/aptirepo-http
	mkdir -p $(DESTDIR)/etc/aptirepo

clean-for-install:
	npm prune

install: clean-for-install install-dirs
	cp -a distributions $(DESTDIR)/etc/aptirepo/
	cp -a \
		*.js \
		*.json \
		*.html \
		bin \
		node_modules \
	$(DESTDIR)$(prefix)/lib/node_modules/aptirepo-http

clean:
	rm -rf node_modules

clean-deb:
	rm -f ../aptirepo-http*.dsc
	rm -f ../aptirepo-http*.deb
	rm -f ../aptirepo-http*.changes
	rm -f ../aptirepo-http*.tar.gz
