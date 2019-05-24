subdirs         := admins                     \
                   autopilot                  \
                   autopoweroff               \
                   bigtouch-shutdown          \
                   blackboard                 \
                   client                     \
                   conf                       \
                   core                       \
                   desktop-applet             \
                   devscripts                 \
                   fluent-plugin-puavo        \
                   hw-log                     \
                   hw-tools                   \
                   iivari                     \
                   ltsp                       \
                   pam                        \
                   pkg                        \
                   puavomenu                  \
                   sharedir                   \
                   tftp                       \
                   usb-factory                \
                   user-registration          \
                   vpn                        \
                   webkiosk-language-selector \
                   webwindow                  \
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
