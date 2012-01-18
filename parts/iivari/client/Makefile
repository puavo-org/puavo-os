prefix ?= /usr

BINFILES ?= bin/iivari-display_off \
	    bin/iivari-display_on \
	    bin/iivari-display_test_pattern \
	    bin/iivari-kiosk

IIVARIFILES ?= iivari/assets/standby.html \
	       iivari/assets/Telefunken_FuBK_test_pattern.png \
	       iivari/assets/Telefunken_FuBK_test_pattern.svg \
	       iivari/cookiejar.py \
	       iivari/display.py \
	       iivari/__init__.py \
	       iivari/kiosk.py \
	       iivari/logger/cloghandler.py \
	       iivari/logger/crc_logger.py \
	       iivari/logger/__init__.py \
	       iivari/logger/portalocker.py \
	       iivari/main.py \
	       iivari/repl.py \
	       iivari/settings.py \
	       iivari/tests/cookiejar_tests.py \
	       iivari/tests/display_tests.py \
	       iivari/tests/__init__.py

all:

install:
	for binfile in $(BINFILES); do \
	  install -D -o root -g root -m 755 $$binfile \
		  $(DESTDIR)$(prefix)/$$binfile || exit 1; \
	done
	for iivarifile in $(IIVARIFILES); do \
	  install -D -o root -g root -m 644 $$iivarifile \
		  $(DESTDIR)$(prefix)/share/pyshared/$$iivarifile || exit 1; \
	done

clean:
