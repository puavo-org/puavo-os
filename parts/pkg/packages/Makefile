packagedirs = $(sort $(dir $(wildcard */)))
packagefiles = $(packagedirs:%/=%.tar.gz)

all: $(packagefiles) installer-bundle.tar

installer-bundle.tar: $(packagefiles)
	tar cvf "$@" $^

%.tar.gz: %/ %/*
	tar zcvf "$@" $<

clean:
	rm -rf $(packagefiles) installer-bundle.tar

.PHONY: all clean
