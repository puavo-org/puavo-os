INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

appdir = /opt/puavo-wlancontroller
vardir = /var/opt/puavo-wlancontroller

all:
	bundle install --deployment

install: all installdirs
	cp -r .bundle vendor $(DESTDIR)$(appdir)
	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)	\
		Gemfile				\
		Gemfile.lock			\
		config.ru			\
		permstore.rb			\
		root.rb				\
		tempstore.rb

installdirs:
	mkdir -p $(DESTDIR)$(appdir)
	mkdir -p $(DESTDIR)$(vardir)

clean:
	rm -rf .bundle vendor

.PHONY: all clean install installdirs
