
all: npm-install wlan orgindex

npm-install:
	npm install

wlan:
	node_modules/.bin/r.js -o mainConfigFile=public/scripts/config.js name=wlan-start out=public/scripts/wlan-bundle.js
orgindex:
	node_modules/.bin/r.js -o mainConfigFile=public/scripts/config.js name=orgindex-start out=public/scripts/orgindex-bundle.js

build: wlan orgindex

