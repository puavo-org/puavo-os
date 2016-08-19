#!/usr/bin/make -f
# Paul Sladen 2011-09-27, Copyright 2011 Canonical Ltd.  Released under the terms of the GNU GPLv3
WEIGHTS=R B RI BI
BASES=$(foreach WEIGHT,$(WEIGHTS),UbuntuMono-$(WEIGHT))

# These are hardcoded for the moment
# FONT_DESCENT = PPEM - FONT_DESCENT
# WIDTH = PPEM / 2
# AVERAGE_WIDTH = WIDTH * 10
HEIGHT=16
WIDTH=8
AVERAGE_WIDTH=80
FONT_DESCENT=3
WH=-$(WIDTH)x$(HEIGHT)

all: $(foreach BASE,$(BASES),$(BASE)$(WH).psf)
#all: $(foreach BASE,$(BASES),$(BASE)$(WH).psf $(BASE)$(WH).bdf $(BASE)$(WH).cp437.psf)

grub: $(foreach BASE,$(BASES),$(BASE)$(WH).pf2)

%$(WH).bdf: ../../%.ttf
	otf2bdf -f 'Ubuntu Font Family' -t 'Ubuntu Mono' -c M -p $(HEIGHT) -r 72 $< | sed -e "s/\(AVERAGE_WIDTH\).*/\1 $(AVERAGE_WIDTH)/;s/\(FONT_DESCENT\).*/\1 $(FONT_DESCENT)/" > $@

#%.psf: %.bdf
#	bdf2psf --fb $< /usr/share/bdf2psf/standard.equivalents /usr/share/bdf2psf/required.set+/usr/share/bdf2psf/useful.set 256 $@
#	bdf2psf --fb $< /usr/share/bdf2psf/standard.equivalents debug.set+/usr/share/bdf2psf/required.set+/usr/share/bdf2psf/useful.set 256 $@

%.psf: %.bdf
	bdf2psf --fb $< '' debug.set+cp437.set 256 $@

# sudo apt-get install grub-common for 'grub-mkfont'
%$(WH).pf2: ../../%.ttf
	grub-mkfont -o $@ -s $(HEIGHT) -d 3 $<

setfont: UbuntuMono-R.psf
	setfont $<

setfontbold: UbuntuMono-B.psf
	setfont $<

clean:
	-rm -f *.psf *.bdf *.pf2

build: all

.PHONY: all clean setfont build grub
