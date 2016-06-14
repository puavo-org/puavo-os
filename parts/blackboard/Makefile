all: icons.py

icons.py: icons.qrc icons/*.png
	pyrcc5 $< >$@

clean:
	rm -f icons.py

.PHONY: all clean
