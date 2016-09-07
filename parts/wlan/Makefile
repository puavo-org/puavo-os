subdirs = ap gw mapper ruby-puavowlan controller-munin-plugin
install-subdirs = $(subdirs:%=install-%)
clean-subdirs = $(subdirs:%=clean-%)

.PHONY : all
all : $(subdirs)

.PHONY : $(subdirs)
$(subdirs) :
	$(MAKE) -C $@

.PHONY : $(install-subdirs)
$(install-subdirs) :
	$(MAKE) -C $(@:install-%=%) install

.PHONY : install
install : $(install-subdirs)

.PHONY : $(clean-subdirs)
$(clean-subdirs) :
	$(MAKE) -C $(@:clean-%=%) clean

.PHONY : dist
dist :
	@git archive --format=tar --prefix=puavo-wlan-$(shell git rev-parse HEAD)/ HEAD | gzip >../puavo-wlan-$(shell git rev-parse HEAD).tar.gz
	@echo ../puavo-wlan-$(shell git rev-parse HEAD).tar.gz

.PHONY : clean
clean : $(clean-subdirs)
