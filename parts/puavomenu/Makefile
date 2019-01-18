build:

clean:

install-dirs:
	mkdir -p $(DESTDIR)/etc/puavomenu
	mkdir -p $(DESTDIR)/etc/xdg/autostart
	mkdir -p $(DESTDIR)/opt/puavomenu

install: install-dirs
	cp -R * $(DESTDIR)/opt/puavomenu/
	install -o root -g root -m 644 -t $(DESTDIR)/etc/xdg/autostart \
		puavomenu.desktop

uninstall:
	rm -f $(DESTDIR)/etc/puavomenu
	rm -f $(DESTDIR)/opt/puavomenu
