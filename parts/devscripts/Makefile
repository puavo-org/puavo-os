
prefix = /usr/local
BIN = $(DESTDIR)$(prefix)/bin

all:

install:
	mkdir -p $(BIN)
	install -m 755 bin/puavo-dch $(BIN)
	install -m 755 bin/puavo-deb-release $(BIN)
	install -m 755 bin/mkpkg $(BIN)
	install -m 755 bin/mktar $(BIN)
