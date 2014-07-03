TARBALL = $(shell awk '{printf $$2}' MD5SUMS)

pkgdir=/state/restricted-packages/cmaptools

all: build

$(TARBALL):
	wget \
		--no-use-server-timestamps \
		--no-verbose \
		--no-check-certificate \
		--no-cookies \
		--input-file DOWNLOAD_URL \
		--output-document $(TARBALL).tmp
	mv $(TARBALL).tmp $(TARBALL)

build: $(TARBALL)
	md5sum --check MD5SUMS
	rm -rf build build.tmp
	mkdir build.tmp
	cp $(TARBALL) build.tmp/installer
	chmod +x build.tmp/installer
	mv build.tmp build
	touch build

installdirs:
	mkdir $(DESTDIR)$(pkgdir)

install: installdirs build
	build/installer -f installer.properties -i silent

uninstall:
	rm -rf $(DESTDIR)$(pkgdir)

distclean:
	rm -rf build build.tmp

clean: distclean
	rm -rf $(TARBALL) $(TARBALL).tmp

.PHONY: all clean distclean install installdirs uninstall
