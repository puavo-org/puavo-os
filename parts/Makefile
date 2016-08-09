subdirs         := admins autopilot blackboard client conf core devscripts \
	hw-log hw-tools local-config ltsp monitor pkg rules sharedir vpn wlan
all-subdirs     := $(subdirs:%=.all-%)
clean-subdirs   := $(subdirs:%=.clean-%)

.PHONY: all
all: $(all-subdirs)

.PHONY: clean
clean: $(clean-subdirs)

.PHONY: $(all-subdirs)
$(all-subdirs):
	$(MAKE) -C $(@:.all-%=%)

.PHONY: $(clean-subdirs)
$(clean-subdirs):
	$(MAKE) -C $(@:.clean-%=%) clean
