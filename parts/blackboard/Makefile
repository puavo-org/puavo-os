prefix=/usr/local
bindir=$(prefix)/bin
pylibdir=$(prefix)/lib/python3/dist-packages

all: puavoblackboard/icons.py

puavoblackboard/icons.py: icons.qrc icons/*.svg
	pyrcc5 -o "$@" "$<"

install:
	install -D -m 755 -t '$(DESTDIR)$(bindir)'	\
		blackboard

	install -D -m 644 -t '$(DESTDIR)$(pylibdir)/puavoblackboard'	\
		puavoblackboard/*.py

clean:
	rm -f puavoblackboard/icons.py

.PHONY: all clean
