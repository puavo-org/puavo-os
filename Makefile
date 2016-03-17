subdirs                    := parts
clean-subdirs              := $(subdirs:%=clean-%)
install-subdirs            := $(subdirs:%=install-%)

all                : $(subdirs)
clean              : $(clean-subdirs)
install            : $(install-subdirs)

apt-get-build-dep:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

deb:
	dpkg-buildpackage -us -uc

release:
	@parts/devscripts/bin/git-update-debian-changelog

$(subdirs):
	$(MAKE) -C $@

$(clean-subdirs):
	$(MAKE) -C $(@:clean-%=%) clean

$(install-subdirs):
	$(MAKE) -C $(@:install-%=%) install

.PHONY: $(subdirs)                    \
        $(clean-subdirs)              \
        $(install-subdirs)            \
        all                           \
        clean                         \
	deb                           \
        apt-get-build-dep             \
        install                       \
        release
