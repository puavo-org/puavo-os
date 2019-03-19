# XXX not building iivari-client in Buster at the moment
# XXX because python-pyside dependency is not available
# iivari

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
                   hw-log                     \
                   hw-tools                   \
                   ltsp                       \
                   pam                        \
                   pkg                        \
                   puavomenu                  \
                   sharedir                   \
                   tftp                       \
                   usb-factory                \
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
