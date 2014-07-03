TARBALL = $(shell awk '{printf $$2}' MD5SUMS)

pkgdir=/state/restricted-packages/oracle-java

all: build

$(TARBALL):
	wget \
		--no-use-server-timestamps \
		--no-verbose \
		--no-check-certificate \
		--no-cookies \
		--header "Cookie: oraclelicense=accept-securebackup-cookie" \
		--input-file DOWNLOAD_URL \
		--output-document $(TARBALL).tmp
	mv $(TARBALL).tmp $(TARBALL)

build: $(TARBALL)
	md5sum --check MD5SUMS
	rm -rf build build.tmp
	mkdir build.tmp
	tar -z -x -f $(TARBALL) --strip-components=1 -C build.tmp
	mv build.tmp build
	touch build

installdirs:
	mkdir $(DESTDIR)$(pkgdir)

install: installdirs build
	cp -a -T build $(DESTDIR)$(pkgdir)

	update-alternatives \
		--install \
			$(DESTDIR)/usr/lib/mozilla/plugins/libjavaplugin.so \
			mozilla-javaplugin.so \
			$(DESTDIR)$(pkgdir)/jre/lib/i386/libnpjp2.so \
			1100

	update-alternatives \
		--install \
			$(DESTDIR)/usr/bin/javaws \
			javaws \
			$(DESTDIR)$(pkgdir)/bin/javaws \
			1100 \
		--slave $(DESTDIR)/usr/share/man/man1/javaws.1.gz \
			javaws.1.gz \
			$(DESTDIR)$(pkgdir)/man/man1/javaws.1

uninstall:
	update-alternatives \
		--remove \
			mozilla-javaplugin.so \
			$(DESTDIR)$(pkgdir)/jre/lib/i386/libnpjp2.so

	update-alternatives \
		--remove \
			javaws \
			$(DESTDIR)$(pkgdir)/bin/javaws

	rm -rf $(DESTDIR)$(pkgdir)

distclean:
	rm -rf build build.tmp

clean: distclean
	rm -rf $(TARBALL) $(TARBALL).tmp

.PHONY: all clean distclean install installdirs uninstall
