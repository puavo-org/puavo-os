_pkgs_toolchain := nodejs-bundle
_pkgs           := autopoweroff                 \
                   fluentd                      \
                   gnome-clocks                 \
                   libpam-envfeed               \
                   node-webkit                  \
                   onboard                      \
                   ubuntu-font-family-sources   \
                   visionmedia-mon

_dpkg_buildpackage_toolchain := $(_pkgs_toolchain:%=.dpkg-buildpackage-%)
_dpkg_buildpackage           := $(_pkgs:%=.dpkg-buildpackage-%)

_install_build_deps_toolchain := $(_pkgs_toolchain:%=.install-build-deps-%)
_install_build_deps           := $(_pkgs:%=.install-build-deps-%)

.PHONY: all
all: $(_dpkg_buildpackage)
	$(MAKE) Packages.gz

.PHONY: toolchain
toolchain: $(_dpkg_buildpackage_toolchain)
	$(MAKE) Packages.gz

.PHONY: clean
clean:
	git clean -f -d -x

.dpkg-buildpackage-%: %
	cd $<						\
		&& debian/scripts/get-orig-source	\
		&& dpkg-buildpackage -b -uc		\
		&& ../../parts/devscripts/bin/do-changes -l ../pool

.PHONY: update-repo
update-repo:
	$(MAKE) Packages.gz

Packages: $(wildcard pool/*.deb)
	mkdir -p pool
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

.PHONY: install-build-deps-toolchain
install-build-deps-toolchain: $(_install_build_deps_toolchain)

.PHONY: install-build-deps
install-build-deps: $(_install_build_deps)

.PHONY: $(_install_build_deps) $(_install_build_deps_toolchain)
.install-build-deps-%: %
	mk-build-deps -i "$</debian/control"
