TARBALL = $(shell awk '{printf $$2}' MD5SUMS)

pkgdir=/state/restricted-packages/google-chrome

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

	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/share/applications
	mkdir -p $(DESTDIR)/usr/share/man/man1
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/16x16/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/22x22/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/24x24/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/32x32/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/48x48/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/64x64/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/128x128/apps
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/256x256/apps

install: installdirs build
	cp -a -T build $(DESTDIR)$(pkgdir)

	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_16.png \
		$(DESTDIR)/usr/share/icons/hicolor/16x16/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_22.png \
		$(DESTDIR)/usr/share/icons/hicolor/22x22/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_24.png \
		$(DESTDIR)/usr/share/icons/hicolor/24x24/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_32.png \
		$(DESTDIR)/usr/share/icons/hicolor/32x32/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_48.png \
		$(DESTDIR)/usr/share/icons/hicolor/48x48/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_64.png \
		$(DESTDIR)/usr/share/icons/hicolor/64x64/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_128.png \
		$(DESTDIR)/usr/share/icons/hicolor/128x128/apps/google-chrome.png
	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/product_logo_256.png \
		$(DESTDIR)/usr/share/icons/hicolor/256x256/apps/google-chrome.png

	ln -s $(DESTDIR)$(pkgdir)/usr/share/man/man1/google-chrome.1 \
		$(DESTDIR)/usr/share/man/man1/google-chrome.1

	ln -s $(DESTDIR)$(pkgdir)/usr/share/applications/google-chrome.desktop \
		$(DESTDIR)/usr/share/applications/google-chrome.desktop

	ln -s $(DESTDIR)$(pkgdir)/opt/google/chrome/google-chrome \
		$(DESTDIR)/usr/bin/google-chrome-stable

uninstall:
	rm -f $(DESTDIR)/usr/bin/google-chrome-stable

	rm -f $(DESTDIR)/usr/share/applications/google-chrome.desktop

	rm -f $(DESTDIR)/usr/share/man/man1/google-chrome.1

	rm -f $(DESTDIR)/usr/share/icons/hicolor/256x256/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/128x128/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/64x64/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/32x32/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/24x24/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/22x22/apps/google-chrome.png
	rm -f $(DESTDIR)/usr/share/icons/hicolor/16x16/apps/google-chrome.png

	rm -rf $(DESTDIR)$(pkgdir)

distclean:
	rm -rf build build.tmp

clean: distclean
	rm -rf $(TARBALL) $(TARBALL).tmp

.PHONY: all clean distclean install installdirs uninstall
