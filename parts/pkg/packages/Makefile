prefix = /usr
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

packagedirs  = adobe-flashplugin/
packagedirs += adobe-pepperflashplugin/
packagedirs += adobe-reader/
packagedirs += bluegriffon/
packagedirs += cmaptools/
packagedirs += dropbox/
packagedirs += ekapeli-alku/
packagedirs += geogebra/
packagedirs += google-chrome/
packagedirs += google-earth/
packagedirs += mattermost-desktop/
packagedirs += msttcorefonts/
packagedirs += oracle-java/
packagedirs += processing/
packagedirs += skype/
packagedirs += smartboard/
packagedirs += spotify-client/
packagedirs += tilitin/
packagedirs += t-lasku/
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
