packagedirs = $(sort $(dir $(wildcard */)))
packagefiles = $(packagedirs:%/=%.tar.gz)

all: $(packagefiles)

%.tar.gz: %/ %/*
	tar zcvf "$@" $<

clean:
	rm -rf $(packagefiles)

.PHONY: all clean
