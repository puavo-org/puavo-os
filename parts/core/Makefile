subdirs = add_entropy
install-subdirs = $(subdirs:%=install-%)
clean-subdirs = $(subdirs:%=clean-%)

prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

ifeq ($(prefix), /usr/local)
sysconfdir = $(prefix)/etc
else
sysconfdir = /etc
endif

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all : $(subdirs)

.PHONY : $(subdirs)
$(subdirs) :
	$(MAKE) -C $@

.PHONY : $(install-subdirs)
$(install-subdirs) :
	$(MAKE) -C $(@:install-%=%) install

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/conf.d
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/hooks
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-bottom
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-top
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/puavo-postmount
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-conf/files/etc/pam.d
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-conf/files/messages
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-conf/scripts

.PHONY : install
install : $(install-subdirs) installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs-tools/hooks \
		initramfs-tools/hooks/puavo
	$(INSTALL_PROGRAM) \
		-t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-bottom \
		initramfs-tools/scripts/init-bottom/puavo-nbd-server
	$(INSTALL_PROGRAM) \
		-t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-top \
		initramfs-tools/scripts/init-top/puavo
	$(INSTALL_PROGRAM) \
		-t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/puavo-postmount \
		initramfs-tools/scripts/puavo-postmount/01-mount \
		initramfs-tools/scripts/puavo-postmount/02-plymouth
	$(INSTALL_PROGRAM) -t $(DESTDIR)/sbin init-puavo

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/initramfs-tools/conf.d \
		initramfs-tools/conf.d/puavo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts \
		initramfs-tools/scripts/puavo

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-conf/definitions/*.json
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-conf/files/etc/pam.d/ \
		puavo-conf/files/etc/pam.d/*
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-conf/files/messages/ \
		puavo-conf/files/messages/*
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/puavo-conf/scripts \
		puavo-conf/scripts/*

.PHONY : $(clean-subdirs)
$(clean-subdirs) :
	$(MAKE) -C $(@:clean-%=%) clean

.PHONY : clean
clean : $(clean-subdirs)
