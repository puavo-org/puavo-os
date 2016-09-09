prefix = /usr
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

packagedirs  = adobe-flashplugin/
# packagedirs += adobe-reader/		# no 64-bit version
packagedirs += cmaptools/
packagedirs += dropbox/
packagedirs += geogebra/
packagedirs += google-chrome/
packagedirs += google-earth/
packagedirs += msttcorefonts/
packagedirs += oracle-java/
packagedirs += skype/
packagedirs += spotify-client/
packagedirs += vstloggerpro/

packagefiles = $(packagedirs:%/=%.tar.gz)

.PHONY: all
all: $(packagefiles) puavo-pkg-installers-bundle.tar

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-pkg/packages

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-pkg/packages \
		$(packagefiles)

puavo-pkg-installers-bundle.tar: $(packagefiles)
	tar cf "$@" $^

# Do not use tar with -z, instead use "gzip -n" so that tar-archives are
# deterministically created and thus different only when their contents have
# changed (we use tar-archive contents as installer versions).
%.tar.gz: %/ %/*
	tar --mtime='2000-01-01 00:00:00 +00:00' -c -f - $< | gzip -n > "$@"

.PHONY: clean
clean:
	rm -rf $(packagefiles) puavo-pkg-installers-bundle.tar
