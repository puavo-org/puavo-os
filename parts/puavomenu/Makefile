CC=gcc
CFLAGS=-s -O2 -Wall -Wextra -pedantic -std=c99

.PHONY: all
all: monitor-userprogs

monitor-userprogs: monitor-userprogs.c

.PHONY: build
build: monitor-userprogs

.PHONY: clean
clean:
	rm -rf monitor-userprogs

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)/etc/puavomenu
	mkdir -p $(DESTDIR)/etc/xdg/autostart
	mkdir -p $(DESTDIR)/opt/puavomenu

.PHONY: install
install: install-dirs
	cp -R * $(DESTDIR)/opt/puavomenu/
	install -o root -g root -m 644 -t $(DESTDIR)/etc/xdg/autostart puavomenu.desktop

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)/etc/puavomenu
	rm -f $(DESTDIR)/opt/puavomenu
