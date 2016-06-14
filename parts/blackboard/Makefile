all: icons.py

icons.py: icons.qrc icons/*.svg
	pyrcc5 $< >$@

clean:
	rm -f icons.py

.PHONY: all clean
