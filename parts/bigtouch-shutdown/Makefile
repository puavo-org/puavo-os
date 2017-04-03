prefix = /usr
sbindir= $(prefix)/sbin
datadir = $(prefix)/share/bigtouch-shutdown

CFLAGS = -s -Wall -std=c99
LDFLAGS =

CFLAGS += $(shell pkg-config --cflags gtk+-3.0)
LDFLAGS += $(shell pkg-config --libs gtk+-3.0)

.PHONY: all \
	clean \
	installdirs \
	install

all: shutdown-question

shutdown_question:
	gcc $(CFLAGS) shutdown-question.c -o shutdown-question $(LDFLAGS)

installdirs:
	mkdir -p '$(DESTDIR)$(sbindir)'
	mkdir -p '$(DESTDIR)$(datadir)'

install: installdirs
	install -m 755 shutdown-question '$(DESTDIR)$(sbindir)'
	install -m 755 ask-shutdown-question '$(DESTDIR)$(sbindir)'
	install -m 644 shutdown-question.ui '$(DESTDIR)$(datadir)'

clean:
	rm -f shutdown-question
