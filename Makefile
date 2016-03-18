subdirs         := parts
clean-subdirs   := $(subdirs:%=clean-%)
install-subdirs := $(subdirs:%=install-%)

changes_file = ../$(shell dpkg-parsechangelog -SSource)_$(shell dpkg-parsechangelog -SVersion)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes

all: $(subdirs)
clean: $(clean-subdirs)
install: $(install-subdirs)

apt-get-build-dep:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

debs: release
	dpkg-buildpackage -us -uc
	parts/devscripts/bin/cp-changes "$(changes_file)" debs
	@echo Done.

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
        apt-get-build-dep             \
        clean                         \
        debs                          \
        install                       \
        release
