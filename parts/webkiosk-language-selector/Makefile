prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 0644

FLAGS_PATH = /puavo-webkiosk-language-selector/flags
SCREENSAVER_PATH = /puavo-webkiosk-language-selector/screensaver

FLAG_IMAGES = \
	images/flags/de.png \
	images/flags/en.png \
	images/flags/fi.png \
	images/flags/sv.png

SCREENSAVER_IMAGES = images/screensaver

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)$(FLAGS_PATH)
	mkdir -p $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/de
	mkdir -p $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/en
	mkdir -p $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/fi
	mkdir -p $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/sv

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) webkiosk-language-selector
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) webkiosk-activate-screensaver
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)$(FLAGS_PATH) ${FLAG_IMAGES}
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/de \
		${SCREENSAVER_IMAGES}/de.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/en \
		${SCREENSAVER_IMAGES}/en.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/fi \
		${SCREENSAVER_IMAGES}/fi.png
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)$(SCREENSAVER_PATH)/sv \
		${SCREENSAVER_IMAGES}/sv.png

.PHONY: clean
clean:
