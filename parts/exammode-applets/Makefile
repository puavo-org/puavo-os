SUBDIRS = setup-applet

.PHONY: all install clean
all install clean:
	@for dir in $(SUBDIRS); do (cd "$${dir}" && $(MAKE) $@); done
