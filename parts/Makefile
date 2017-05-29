subdirs         := admins                       \
                   autopilot                    \
                   bigtouch-shutdown            \
                   blackboard                   \
                   client                       \
                   conf                         \
                   core                         \
                   devscripts                   \
                   hw-log                       \
                   hw-tools                     \
                   iivari                       \
                   local-config                 \
                   ltsp                         \
                   opinsys-ca-certificates      \
                   pam                          \
                   pkg                          \
                   sharedir                     \
                   vpn                          \
                   webkiosk-language-selector   \
                   webmenu                      \
                   wlan
subdirs-all     := $(subdirs:%=.all-%)
subdirs-clean   := $(subdirs:%=.clean-%)
subdirs-install := $(subdirs:%=.install-%)

.PHONY: all
all: $(subdirs-all)

.PHONY: clean
clean: $(subdirs-clean)

.PHONY: install
install: $(subdirs-install)

.PHONY: $(subdirs-all)
$(subdirs-all):
	$(MAKE) -C $(@:.all-%=%)

.PHONY: $(subdirs-clean)
$(subdirs-clean):
	$(MAKE) -C $(@:.clean-%=%) clean

.PHONY: $(subdirs-install)
$(subdirs-install):
	$(MAKE) -C $(@:.install-%=%) install
