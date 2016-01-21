subdirs                    := $(sort $(shell find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'))
clean-subdirs              := $(subdirs:%=clean-%)
deb-subdirs                := $(subdirs:%=deb-%)
install-build-deps-subdirs := $(subdirs:%=install-build-deps-%)
install-subdirs            := $(subdirs:%=install-%)

all                : $(subdirs)
clean              : $(clean-subdirs)
deb                : $(deb-subdirs)
install-build-deps : $(install-build-deps-subdirs)
install            : $(install-subdirs)

$(subdirs):
	$(MAKE) -C $@

$(clean-subdirs):
	rm -rf *.deb *.dsc *.tar.* *.changes
	$(MAKE) -C $(@:clean-%=%) clean

$(deb-subdirs):
	$(MAKE) -C $(@:deb-%=%) deb

$(install-build-deps-subdirs):
	$(MAKE) -C $(@:install-build-deps-%=%) install-build-deps

$(install-subdirs):
	$(MAKE) -C $(@:install-%=%) install

.PHONY: $(subdirs)                \
        $(clean-subdirs)              \
        $(install-build-deps-subdirs) \
        $(install-subdirs)            \
        all                           \
        clean                         \
        install-build-deps            \
        install
