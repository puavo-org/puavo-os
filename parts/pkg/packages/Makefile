prefix = /usr
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

packagedirs  = abitti-naksu
packagedirs  = adobe-flashplugin
packagedirs += adobe-flashplugin-32bit
packagedirs += adobe-pepperflashplugin
packagedirs += adobe-pepperflashplugin-32bit
packagedirs += adobe-reader
packagedirs += airtame
packagedirs += appinventor
packagedirs += arduino-ide
packagedirs += arduino-radiohead
packagedirs += arduino-TM1637
packagedirs += bluegriffon
# XXX do not build, not ready # packagedirs += casio-classpad-manager-for-ii
packagedirs += canon-cque
packagedirs += cmaptools
packagedirs += cnijfilter2
packagedirs += cura-appimage
packagedirs += dropbox
packagedirs += dragonbox_koulu1
packagedirs += ekapeli-alku
packagedirs += enchanting
packagedirs += extra-xkb-symbols
packagedirs += flashforge-flashprint
packagedirs += geogebra
packagedirs += geogebra6
packagedirs += globilab
packagedirs += google-chrome
packagedirs += google-earth
packagedirs += idid
packagedirs += kdenlive-appimage
packagedirs += kojo
packagedirs += mafynetti
packagedirs += marvinsketch
packagedirs += mattermost-desktop
packagedirs += msttcorefonts
packagedirs += nightcode
packagedirs += obsidian-icons
packagedirs += ohjelmointi-opetuksessa
packagedirs += openscad-nightly
packagedirs += openshot-appimage
packagedirs += oracle-java
packagedirs += processing
packagedirs += promethean
packagedirs += pycharm
packagedirs += robboscratch2
packagedirs += robotmeshconnect
packagedirs += skype
packagedirs += smartboard
packagedirs += spotify-client
packagedirs += tilitin
packagedirs += t-lasku
packagedirs += vidyo-client
packagedirs += vstloggerpro

packagefiles = $(patsubst %,%.tar.gz,${packagedirs})

.PHONY: all
all: $(packagefiles) puavo-pkg-installers-bundle.tar puavo-pkg.json
	echo $(packagefiles)

puavo-pkg.json: $(packagefiles)
	jq --null-input --arg packages "$(packagedirs)" \
	  '$$packages | split(" ") | reduce .[] as $$item ({}; .["puavo.pkg." + $$item] = { default: "do-nothing" })' \
	  > $@.tmp
	mv $@.tmp $@

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-pkg/packages

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-pkg.json
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-pkg/packages \
		$(packagefiles)

puavo-pkg-installers-bundle.tar: $(packagefiles)
	tar cf "$@" $^

# Do not use tar with -z, instead use "gzip -n" so that tar-archives are
# deterministically created and thus different only when their contents have
# changed (we use tar-archive contents as installer versions).
# XXX The above comment implies that the outcome is exactly the same on
# XXX different hosts, given the same directory tree (paths and contents).
# XXX This is *not* true, but should be.
%.tar.gz: %/ %/*
	./update_package_version $(patsubst %.tar.gz,%,$@)
	tar --mtime='2000-01-01 00:00:00 +00:00' -c -f - $< | gzip -n > "$@"

.PHONY: clean
clean:
	rm -rf $(packagefiles) puavo-pkg-installers-bundle.tar
