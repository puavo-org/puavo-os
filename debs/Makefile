# parts, ports and some cloud packages go into puavo-os images

_pkgs_cloud := krb5 openldap puavo-ds puavo-os
_pkgs_parts := puavo-ds puavo-os
_pkgs_ports := anki                   \
               console-setup          \
               cups                   \
               cups-filters           \
               gnome-control-center   \
               gnome-network-displays \
               gnome-shell            \
               gtk+3.0                \
               gtk4                   \
               hooktftp               \
               libpam-ccreds          \
               linux                  \
               mutter                 \
               nbd                    \
               veyon                  \
               wine                   \
               wsmancli

# XXX disabled for bookworm
#                kde-spectacle          \

# sblim-sfcc openwsman are dependencies for wsmancli
_pkgs_cloud_builddeps :=
_pkgs_parts_builddeps :=
_pkgs_ports_builddeps := sblim-sfcc openwsman

_pkgs_image := $(_pkgs_parts_builddeps) $(_pkgs_ports_builddeps) \
               $(_pkgs_parts) $(_pkgs_ports)

_pkgs_web   := $(_pkgs_cloud_builddeps) $(_pkgs_cloud)

debs_build_targets           := $(sort $(_pkgs_image:%=debs-build-%) $(_pkgs_web:%=debs-build-%))

_dpkg_buildpackage_cloud     := $(_pkgs_cloud:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts     := $(_pkgs_parts:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports     := $(_pkgs_ports:%=.dpkg-buildpackage-%)
_dpkg_buildpackage           := $(_pkgs_image:%=.dpkg-buildpackage-%)

_dpkg_buildpackage_cloud_builddeps := \
  $(_pkgs_cloud_builddeps:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts_builddeps := \
  $(_pkgs_parts_builddeps:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports_builddeps := \
  $(_pkgs_ports_builddeps:%=.dpkg-buildpackage-%)

reset_debian_targets := $(_pkgs_ports:%=reset-debian-%)

_workdir = .workdir

.PHONY: all
all: $(_dpkg_buildpackage)

.PHONY: cloud-builddeps
cloud-builddeps: $(_dpkg_buildpackage_cloud_builddeps)

.PHONY: parts-builddeps
parts-builddeps: $(_dpkg_buildpackage_parts_builddeps)

.PHONY: ports-builddeps
ports-builddeps: $(_dpkg_buildpackage_ports_builddeps)

.PHONY: cloud
cloud: $(_dpkg_buildpackage_cloud)

.PHONY: parts
parts: $(_dpkg_buildpackage_parts)

.PHONY: ports
ports: $(_dpkg_buildpackage_ports)

.PHONY: clean
clean:
	rm -rf .archive $(_workdir)

_sudo ?= sudo
.PHONY: $(debs_build_targets)
$(debs_build_targets): debs-build-%: %
	@env PUAVOOS_SUDO='$(_sudo)' \
	    ../.aux/debs-build "$<" "$(_workdir)" "$(CURDIR)/.archive/pool"

.dpkg-buildpackage-%: debs-build-%
	$(MAKE) update-repo
	$(_sudo) apt-get update

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

.PHONY: $(reset_debian_targets)
$(reset_debian_targets): reset-debian-%: %
	cd '$<' && ../../.aux/debs-reset-debian
