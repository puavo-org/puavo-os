packages = $(shell find $(CURDIR) -mindepth 1 -maxdepth 1 -type d -printf '%f ')
install-packages = $(packages:%=install-%)
uninstall-packages = $(packages:%=uninstall-%)
clean-packages = $(packages:%=clean-%)
distclean-packages = $(packages:%=distclean-%)

all : $(packages)

$(packages) :
	$(MAKE) -C $@

$(install-packages) :
	$(MAKE) -C $(@:install-%=%) install

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

.PHONY : all clean distclean install uninstall \
	$(packages) $(clean-packages) $(distclean-packages) \
	$(install-packages) $(uninstall-packages)
