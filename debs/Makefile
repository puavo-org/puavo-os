# sblim-sfcc openwsman are dependencies for wsmancli
_pkgs_builddeps := sblim-sfcc openwsman

# parts, ports and some cloud packages go into puavo-os images

_pkgs_parts := puavo-ds puavo-os
# XXX gvfs not added to build, because it is unclear
# XXX if there is any benefit to do so
_pkgs_ports := fmit          \
               gnome-shell   \
               grub2         \
               incron        \
               libmypaint    \
               libpam-ccreds \
               mutter        \
               mypaint       \
               nbd           \
               openboard     \
               openldap      \
               pinta         \
               vtun          \
               wine          \
               wsmancli
_pkgs_image     := $(_pkgs_builddeps) $(_pkgs_parts) $(_pkgs_ports)
_pkgs_cloud     := krb5 openldap puavo-ds

_dpkg_buildpackage_builddeps := $(_pkgs_builddeps:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_cloud     := $(_pkgs_cloud:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts     := $(_pkgs_parts:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports     := $(_pkgs_ports:%=.dpkg-buildpackage-%)
_dpkg_buildpackage           := $(_pkgs_image:%=.dpkg-buildpackage-%)

_workdir = .workdir

.PHONY: all
all: $(_dpkg_buildpackage)

.PHONY: builddeps
builddeps: $(_dpkg_buildpackage_builddeps)

.PHONY: cloud
cloud: $(_dpkg_buildpackage_cloud)

.PHONY: parts
parts: $(_dpkg_buildpackage_parts)

.PHONY: ports
ports: $(_dpkg_buildpackage_ports)

.PHONY: clean
clean:
	rm -rf .archive $(_workdir)

.dpkg-buildpackage-%: % apt_update
	@env PUAVOOS_SUDO='$(_sudo)' \
	    ../.aux/build-debs "$<" "$(_workdir)" "$(CURDIR)/.archive/pool"
	$(MAKE) update-repo

.PHONY: prepare
prepare: $(_workdir) update-repo

.PHONY: update-repo
update-repo:
	$(MAKE) .archive/Release

.PHONY: remove-build-deps
remove-build-deps:
	$(_sudo) apt-get -y purge \
	    $$(echo $(patsubst %,%-build-deps,$(_pkgs_image)) \
		 | xargs -n 1 dpkg --status 2>/dev/null \
		 | awk '$$1 == "Package:" { print $$2 }')

$(_workdir):
	mkdir -p $(_workdir)

.archive/Packages: $(wildcard .archive/pool/*.deb)
	mkdir -p .archive/pool
	cd .archive && apt-ftparchive packages pool > Packages

.archive/Packages.gz: .archive/Packages
	gzip -f -k $<

.archive/Release: .archive/Packages.gz
	cd .archive && apt-ftparchive \
	    -o APT::FTPArchive::Release::Origin=puavo-os-local release . \
	    > Release

.PHONY: apt_update
apt_update:
	$(_sudo) apt-get update
