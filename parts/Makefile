subdirs         := admins                       \
                   autopilot                    \
                   blackboard                   \
                   client                       \
                   conf                         \
                   core                         \
                   devscripts                   \
                   hw-log                       \
                   hw-tools                     \
                   local-config                 \
                   ltsp                         \
                   opinsys-ca-certificates      \
                   pkg                          \
                   rules                        \
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
