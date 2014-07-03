TARBALL = $(shell awk '{printf $$2}' MD5SUMS)

pkgdir=/state/restricted-packages/adobe-reader

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
	dpkg -x $(TARBALL) build.tmp
	mv build.tmp build
	touch build

installdirs:
	mkdir $(DESTDIR)$(pkgdir)
	mkdir -p $(DESTDIR)/etc/bash_completion.d
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/share/applications
	mkdir -p $(DESTDIR)/usr/share/man/man1
	mkdir -p $(DESTDIR)/usr/share/pixmaps

install: installdirs build
	cp -a -T build $(DESTDIR)$(pkgdir)

	ln -s $(DESTDIR)$(pkgdir)/opt/Adobe/Reader9/Resource/Icons/48x48/AdobeReader9.png \
		$(DESTDIR)/usr/share/pixmaps/AdobeReader9.png
	ln -s $(DESTDIR)$(pkgdir)/opt/Adobe/Reader9/Resource/Shell/acroread.1.gz \
		$(DESTDIR)/usr/share/man/man1/acroread.1.gz
	ln -s $(DESTDIR)$(pkgdir)/opt/Adobe/Reader9/Resource/Shell/acroread_tab \
		$(DESTDIR)/etc/bash_completion.d/acroread.sh
	ln -s $(DESTDIR)$(pkgdir)/opt/Adobe/Reader9/Resource/Support/AdobeReader.desktop \
		$(DESTDIR)/usr/share/applications/acroread.desktop
	ln -s $(DESTDIR)$(pkgdir)/opt/Adobe/Reader9/bin/acroread \
		$(DESTDIR)/usr/bin/acroread

uninstall:
	rm -f $(DESTDIR)/usr/bin/acroread
	rm -f $(DESTDIR)/usr/share/applications/acroread.desktop
	rm -f $(DESTDIR)/etc/bash_completion.d/acroread.sh
	rm -f $(DESTDIR)/usr/share/man/man1/acroread.1.gz
	rm -f $(DESTDIR)/usr/share/pixmaps/AdobeReader9.png

	rm -rf $(DESTDIR)$(pkgdir)

distclean:
	rm -rf build build.tmp

clean: distclean
	rm -rf $(TARBALL) $(TARBALL).tmp

.PHONY: all clean distclean install installdirs uninstall

