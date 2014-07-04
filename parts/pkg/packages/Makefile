DESTDIR ?= /state/restricted-packages
packages = $(shell find $(CURDIR) -mindepth 1 -maxdepth 1 -type d -printf '%f ')
downloads = $(packages:%=%/upstream.pack)
builddirs = $(packages:%=%/build)
installdirs = $(packages:%=$(installroot)/%)
install-packages = $(packages:%=install-%)
uninstall-packages = $(packages:%=uninstall-%)
clean-packages = $(packages:%=clean-%)
distclean-packages = $(packages:%=distclean-%)

all : $(builddirs)

$(downloads):
	./download $@

download : $(downloads)

$(builddirs): %/build : %/upstream.pack
	cd $(@:%/build=%) && md5sum --check MD5SUMS
	rm -rf $@ $@.tmp
	mkdir $@.tmp
	$(MAKE) -C $(@:%/build=%) -f rules.mk build
	mv $@.tmp $@
	touch $@

build : $(builddirs)

$(install-packages) :
	mkdir $(DESTDIR)/$(@:install-%=%)
	cp -r -t $(DESTDIR)/$(@:install-%=%) $(@:install-%=%/build)
	$(MAKE) -C $(@:install-%=%) -f rules.mk install DESTDIR=$(DESTDIR)/$(@:install-%=%/build)

install : $(install-packages)

$(uninstall-packages) :
	$(MAKE) -C $(@:uninstall-%=%) uninstall

uninstall : $(uninstall-packages)

$(clean-packages) :
	$(MAKE) -C $(@:clean-%=%) clean

$(distclean-packages) :
	$(MAKE) -C $(@:distclean-%=%) distclean

clean : $(clean-packages)

distclean : $(distclean-packages)

.PHONY : all download build clean distclean install uninstall \
	$(packages) $(clean-packages) $(distclean-packages) \
	$(install-packages) $(uninstall-packages)
