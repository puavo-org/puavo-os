INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: build
build:

.PHONY: format
format:
	black .

.PHONY: clean
clean:

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)/etc/puavomenu     \
	         $(DESTDIR)/etc/xdg/autostart \
	         $(DESTDIR)/opt/puavomenu

.PHONY: install
install: install-dirs
	cp -R * $(DESTDIR)/opt/puavomenu/
	$(INSTALL_DATA) -t $(DESTDIR)/etc/xdg/autostart puavomenu.desktop

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)/etc/puavomenu $(DESTDIR)/opt/puavomenu
