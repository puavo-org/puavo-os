SUBDIRS = browser puavo-exammode@puavo.org session-applet setup-applet

.PHONY: all install clean
all install clean:
	@for dir in $(SUBDIRS); do (cd "$${dir}" && $(MAKE) $@) || exit 1; done
