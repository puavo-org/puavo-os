packagedirs = adobe-flashplugin/ adobe-reader/ cmaptools/ dropbox/ \
	google-chrome/ google-earth/ oracle-java/ skype/ vstloggerpro/
packagefiles = $(packagedirs:%/=%.tar.gz)

all: $(packagefiles) puavo-pkg-installers-bundle.tar

puavo-pkg-installers-bundle.tar: $(packagefiles)
	tar cvf "$@" $^

%.tar.gz: %/ %/*
	tar zcvf "$@" $<

clean:
	rm -rf $(packagefiles) puavo-pkg-installers-bundle.tar

.PHONY: all clean
