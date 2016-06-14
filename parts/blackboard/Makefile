all: puavo/blackboard/icons.py

puavo/blackboard/icons.py: icons.qrc icons/*.svg
	pyrcc5 $< >$@

clean:
	rm -f puavo/blackboard/icons.py

.PHONY: all clean
