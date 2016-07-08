subdirs         := admins autopilot blackboard client conf core devscripts \
	hw-log hw-tools local-config ltsp monitor pkg rules sharedir vpn wlan
build-subdirs   := $(subdirs:%=build-%)
clean-subdirs   := $(subdirs:%=clean-%)
install-subdirs := $(subdirs:%=install-%)

.PHONY: all
all: build

.PHONY: build
build: $(subdirs)

.PHONY: clean
clean: $(clean-subdirs)

.PHONY: install
install: $(install-subdirs)

.PHONY: $(subdirs)
$(subdirs):
	$(MAKE) -C $@

.PHONY: $(clean-subdirs)
$(clean-subdirs):
	$(MAKE) -C $(@:clean-%=%) clean

.PHONY: $(install-subdirs)
$(install-subdirs):
	$(MAKE) -C $(@:install-%=%) install
