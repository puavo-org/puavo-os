prefix = /usr/local
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

subdirs = client manager
install-subdirs = $(subdirs:%=install-%)
clean-subdirs = $(subdirs:%=clean-%)

.PHONY : all
all : $(subdirs)

.PHONY : $(subdirs)
$(subdirs) :
	$(MAKE) -C $@

.PHONY : $(install-subdirs)
$(install-subdirs) :
	$(MAKE) -C $(@:install-%=%) install

.PHONY : installdirs
installdirs : $(install-subdirs)
	mkdir -p $(DESKTOP)$(datarootdir)/puavo-conf/definitions

.PHONY : install
install : $(install-subdirs)
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-sharedir.json

.PHONY : $(clean-subdirs)
$(clean-subdirs) :
	$(MAKE) -C $(@:clean-%=%) clean

.PHONY : clean
clean : $(clean-subdirs)
