prefix = /usr/local

build:
	npm install --registry http://registry.npmjs.org

install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/lib/node_modules/debbox

clean-for-install:
	npm prune

install: clean-for-install install-dirs
	cp -a \
		*.js \
		*.json \
		*.html \
		bin \
		node_modules \
	$(DESTDIR)$(prefix)/lib/node_modules/debbox/

clean:
	rm -rf node_modules
