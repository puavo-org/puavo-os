TARBALL = $(shell awk '{printf $$2}' MD5SUMS)

pkgdir=/state/restricted-packages/adobe-flashplugin

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
	tar -z -x -f $(TARBALL) -C build.tmp
	mv build.tmp build
	touch build

installdirs:
	mkdir $(DESTDIR)$(pkgdir)

install: installdirs build
	cp -a -T build $(DESTDIR)$(pkgdir)

	update-alternatives \
		--install \
			$(DESTDIR)/usr/lib/mozilla/plugins/flashplugin-alternative.so \
			mozilla-flashplugin \
			$(DESTDIR)$(pkgdir)/libflashplayer.so \
			50

uninstall:
	update-alternatives \
		--remove \
			mozilla-flashplugin \
			$(DESTDIR)$(pkgdir)/libflashplayer.so

	rm -rf $(DESTDIR)$(pkgdir)

distclean:
	rm -rf build build.tmp

clean: distclean
	rm -rf $(TARBALL) $(TARBALL).tmp

.PHONY: all clean distclean install installdirs uninstall
