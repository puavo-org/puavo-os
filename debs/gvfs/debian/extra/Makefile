all:

wrappers = \
	cat \
	copy \
	info \
	ls \
	mime \
	mkdir \
	monitor-dir \
	monitor-file \
	mount \
	move \
	open \
	rename \
	rm \
	save \
	set-attribute \
	trash \
	tree \
	$(NULL)

# Some gvfs-foo don't map to gio foo
gvfs-ls := list
gvfs-set-attribute := set
gvfs-rm := remove
gvfs-monitor-dir := monitor
gvfs-monitor-file := monitor

# look up a "variable variable" in the list above, otherwise return $@ with
# gvfs- removed
gvfs-name = $(if $($(basename $@)),$($(basename $@)),$(basename $(patsubst gvfs-%,%,$@)))

ALL_BINARIES=$(patsubst %,gvfs-%,$(wrappers))
ALL_MANS=$(addsuffix .1, $(ALL_BINARIES))

all: $(ALL_BINARIES)
all-man: $(ALL_MANS) gvfs-less.1

$(ALL_MANS:.1=.xml): deprecated.xml.in
	sed -e 's,@original@,$(basename $@),g' -e 's,@replacement@,gio $(gvfs-name),' < $< > $@.tmp
	chmod 0755 $@.tmp
	mv $@.tmp $@

gvfs-%.1: gvfs-%.xml
	  xsltproc \
	  --output $@ \
	  --nonet \
	  --stringparam man.output.quietly 1 \
	  --stringparam funcsynopsis.style ansi \
	  --stringparam man.th.extra1.suppress 1 \
	  --stringparam man.authors.section.enabled 0 \
	  --stringparam man.copyright.section.enabled 0 \
	  http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl \
	  $<

gvfs-%: deprecated.in
	sed -e 's,@command@,$(gvfs-name),g' < $< > $@.tmp
	chmod 0755 $@.tmp
	mv $@.tmp $@

clean:
	rm -f $(ALL_BINARIES) $(ALL_MANS) gvfs-less.1
	rm -f *.tmp $(ALL_MANS:.1=.xml)

clean-man:
	rm -f $(ALL_MANS) gvfs-less.1 $(ALL_MANS:.1=.xml)


.PHONY: all-man
