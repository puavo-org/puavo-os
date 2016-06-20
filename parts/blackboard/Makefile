all: puavoblackboard/icons.py

puavoblackboard/icons.py: icons.qrc icons/*.svg
	pyrcc5 -o "$@" "$<"

clean:
	rm -f puavoblackboard/icons.py

.PHONY: all clean
