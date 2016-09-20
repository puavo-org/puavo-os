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
		app.rb				\
		tempstore.rb			\
		oui.txt

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/public	\
		public/*

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/routes	\
		routes/*

	$(INSTALL_DATA) -t $(DESTDIR)$(appdir)/views	\
		views/*

installdirs:
	mkdir -p $(DESTDIR)$(appdir)
	mkdir -p $(DESTDIR)$(appdir)/public
	mkdir -p $(DESTDIR)$(appdir)/routes
	mkdir -p $(DESTDIR)$(appdir)/views
	mkdir -p $(DESTDIR)$(vardir)

clean:
	rm -rf .bundle

.PHONY: all clean install installdirs
