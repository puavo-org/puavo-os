subdirs                    := $(sort $(shell find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'))
clean-subdirs              := $(subdirs:%=clean-%)
install-subdirs            := $(subdirs:%=install-%)

all                : $(subdirs)
clean              : $(clean-subdirs)
install            : $(install-subdirs)

$(subdirs):
	$(MAKE) -C $@

$(clean-subdirs):
	$(MAKE) -C $(@:clean-%=%) clean

$(install-subdirs):
	$(MAKE) -C $(@:install-%=%) install

.PHONY: $(subdirs)                    \
        $(clean-subdirs)              \
        $(install-subdirs)            \
        all                           \
        clean                         \
        install
