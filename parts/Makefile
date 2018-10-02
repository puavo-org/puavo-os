subdirs         := admins                     \
                   autopilot                  \
                   bigtouch-shutdown          \
                   blackboard                 \
                   client                     \
                   conf                       \
                   core                       \
                   devscripts                 \
                   fluent-plugin-puavo        \
                   hw-log                     \
                   hw-tools                   \
                   iivari                     \
                   logrelay                   \
                   ltsp                       \
                   pam                        \
                   pkg                        \
                   puavomenu                  \
                   puavo-webwindow            \
                   sharedir                   \
                   tftp                       \
                   vpn                        \
                   webkiosk-language-selector \
                   webmenu                    \
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
