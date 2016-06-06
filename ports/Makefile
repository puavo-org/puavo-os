subdirs					:= $(sort $(shell find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'))
deb-pkg-build-subdirs			:= $(subdirs:%=deb-pkg-build-%)
deb-pkg-install-build-deps-subdirs	:= $(subdirs:%=deb-pkg-install-build-deps-%)
deb-pkg-get-orig-source-subdirs         := $(subdirs:%=deb-pkg-get-orig-source-%)

all:

clean:

deb-pkg-build: $(deb-pkg-build-subdirs)

deb-pkg-get-orig-source: $(deb-pkg-get-orig-source-subdirs)

deb-pkg-install-build-deps: $(deb-pkg-install-build-deps-subdirs)

$(deb-pkg-build-subdirs): deb-pkg-build-%: % deb-pkg-get-orig-source-%
	cd $< && dpkg-buildpackage -b -uc

$(deb-pkg-get-orig-source-subdirs): deb-pkg-get-orig-source-%: %
	cd $< && debian/scripts/get-orig-source

$(deb-pkg-install-build-deps-subdirs): deb-pkg-install-build-deps-%: %
	cd $< && mk-build-deps -i -r -t "apt-get --yes --force-yes" debian/control

.PHONY: $(deb-pkg-build-subdirs)		\
	$(deb-pkg-get-orig-source)		\
	$(deb-pkg-install-build-deps-subdirs)	\
	all					\
	clean					\
	deb-pkg-build				\
	deb-pkg-get-orig-source			\
	deb-pkg-install-build-deps
