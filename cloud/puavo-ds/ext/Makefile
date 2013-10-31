prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

build:

install-dirs:
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/$(datarootdir)/puavo-ds-ext/templates

install: install-dirs
	install -m 755 -t $(DESTDIR)$(sbindir) bin/puavo-ds-setup-ext-server
	install -m 744 -t $(DESTDIR)$(datarootdir)/puavo-ds-ext/templates templates/modules.ldif.erb
	install -m 744 -t $(DESTDIR)$(datarootdir)/puavo-ds-ext/templates templates/slave_database.ldif.erb

clean:
