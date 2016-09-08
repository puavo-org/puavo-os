_pkgs_toolchain := nodejs-bundle
_pkgs_parts     := puavo-os
_pkgs_ports     := autopoweroff                 \
                   fluentd                      \
                   gnome-clocks                 \
                   libpam-envfeed               \
                   node-webkit                  \
                   onboard                      \
                   ubuntu-font-family-sources   \
                   visionmedia-mon
_pkgs           := $(_pkgs_parts) $(_pkgs_ports)

_dpkg_buildpackage_toolchain := $(_pkgs_toolchain:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts     := $(_pkgs_parts:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports     := $(_pkgs_ports:%=.dpkg-buildpackage-%)
_dpkg_buildpackage           := $(_pkgs:%=.dpkg-buildpackage-%)

_install_build_deps_toolchain := $(_pkgs_toolchain:%=.install-build-deps-%)
_install_build_deps_parts     := $(_pkgs_parts:%=.install-build-deps-%)
_install_build_deps_ports     := $(_pkgs_ports:%=.install-build-deps-%)
_install_build_deps           := $(_pkgs:%=.install-build-deps-%)

.PHONY: all
all: $(_dpkg_buildpackage)
	$(MAKE) Packages.gz

.PHONY: toolchain
toolchain: $(_dpkg_buildpackage_toolchain)
	$(MAKE) Packages.gz

.PHONY: parts
parts: $(_dpkg_buildpackage_parts)
	$(MAKE) Packages.gz

.PHONY: ports
ports: $(_dpkg_buildpackage_ports)
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

.PHONY: install-build-deps-parts
install-build-deps-parts: $(_install_build_deps_parts)

.PHONY: install-build-deps-ports
install-build-deps-ports: $(_install_build_deps_ports)

.PHONY: install-build-deps
install-build-deps: $(_install_build_deps)

.install-build-deps-%: %
	sudo apt-get update
	sudo mk-build-deps -i "$</debian/control" \
		-t 'apt-get -y --force-yes'
