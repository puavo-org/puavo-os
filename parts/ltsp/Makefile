subdirs = bootserver client puavo-install tools ruby-puavobs
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

.PHONY : install
install : $(install-subdirs)

.PHONY: install-build-deps
install-build-deps:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

.PHONY : $(clean-subdirs)
$(clean-subdirs) :
	$(MAKE) -C $(@:clean-%=%) clean

.PHONY : clean
clean : $(clean-subdirs)

.PHONY : deb
deb :
	dpkg-buildpackage -us -uc
