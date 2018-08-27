prefix      = /usr/local
exec_prefix = $(prefix)
sbindir     = $(exec_prefix)/sbin

INSTALL         = install
INSTALL_DATA    = $(INSTALL) -m 644
INSTALL_PROGRAM = $(INSTALL)

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

all:

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants
	mkdir -p $(DESTDIR)/lib/systemd/system

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) bin/puavo-sharedir-manager
	cp -R lib/* $(DESTDIR)$(RUBY_LIB_DIR)
	$(INSTALL_DATA) -t $(DESTDIR)/lib/systemd/system \
		systemd/*
	ln -fs -t $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants\
		/lib/systemd/system/puavo-sharedir-manager.service

clean:
