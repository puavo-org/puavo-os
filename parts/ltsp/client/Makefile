prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all : po/fi/puavo-remote-assistance-applet.mo

puavo-remote-assistance-applet.pot: puavo-remote-assistance-applet
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po : po/puavo-client-updater-applet.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo : %.po
	msgfmt $< --output-file $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client/pam
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/default
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-external-files-actions.d
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-remote-assistance-applet
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/route-up
	mkdir -p $(DESTDIR)$(sysconfdir)/init
	mkdir -p $(DESTDIR)$(sysconfdir)/init.d
	mkdir -p $(DESTDIR)$(sysconfdir)/network/if-up.d
	mkdir -p $(DESTDIR)$(sysconfdir)/NetworkManager/dispatcher.d
	mkdir -p $(DESTDIR)$(sysconfdir)/ssh
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)/lib/udev/rules.d
	mkdir -p $(DESTDIR)$(sysconfdir)/X11/Xsession.d
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/icons/hicolor/scalable/status
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/pam-configs
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/profile-overwrites
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/cron.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/cups
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/dbus-1/system.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/default
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ldap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/lightdm
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/network/if-up.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/network/if-post-down.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/pam.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/polkit-1/localauthority/50-local.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/racoon
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/rsyslog.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/samba
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/security
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ssh
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sssd
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sudoers.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/systemd
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/xdg/autostart
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/lib/udev
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/usr/share/X11/xorg.conf.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/var/lib/polkit-1/localauthority/10-vendor.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/xsessions
	mkdir -p $(DESTDIR)$(datarootdir)/xgreeters
	mkdir -p $(DESTDIR)$(datarootdir)/xsessions
	mkdir -p $(DESTDIR)/var/lib/puavo-desktop/shared
	mkdir -p $(DESTDIR)/var/lib/puavo-desktop/users
	mkdir -p $(DESTDIR)/lib/systemd/system
	mkdir -p $(DESTDIR)/lib/systemd/system/multi-user.target.wants

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/pam-configs \
		pam/configs/puavo-local-access

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-conf-parameters.json

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/profile-overwrites \
		profile-overwrites/*.json

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc \
		templates/etc/rsyslog.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/rsyslog.d \
		templates/etc/rsyslog.d/send_to_syslogserver.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ssh \
		templates/etc/ssh/sshd_config

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/pam.d \
		templates/etc/pam.d/gdm-autologin-fatclient \
		templates/etc/pam.d/gdm-autologin-laptop \
		templates/etc/pam.d/gdm-autologin-preinstalled \
		templates/etc/pam.d/gdm-autologin-wirelessaccesspoint \
		templates/etc/pam.d/gdm-password-fatclient \
		templates/etc/pam.d/gdm-password-laptop \
		templates/etc/pam.d/gnome-screensaver-laptop \
		templates/etc/pam.d/sudo-laptop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ldap \
		templates/etc/ldap/ldap.conf \
		templates/etc/ldap/ldap.conf-laptop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/lightdm \
		templates/etc/lightdm/lightdm.conf

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/network/if-up.d \
		etc/network/if-up.d/sssd

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/icons/hicolor/scalable/status \
		icons/puavoremoteaccess-cyan.svg \
		icons/puavoremoteaccess-green.svg \
		icons/puavoremoteaccess-grey.svg \
		icons/puavoremoteaccess-original.svg \
		icons/puavoremoteaccess-yellow.svg

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc \
		templates/etc/hosts \
		templates/etc/idmapd.conf \
		templates/etc/krb5.conf \
		templates/etc/krb5.conf-laptop \
		templates/etc/nscd.conf \
		templates/etc/nslcd.conf \
		templates/etc/nsswitch.conf-extrausers \
		templates/etc/nsswitch.conf-ldap \
		templates/etc/nsswitch.conf-sss \
		templates/etc/nsswitch.conf-sss-extrausers \
		templates/etc/ntp.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/cron.d \
		templates/etc/cron.d/infotv_display_control

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/cups \
		templates/etc/cups/client.conf \
		templates/etc/cups/cupsd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/dbus-1/system.d \
		templates/etc/dbus-1/system.d/org.freedesktop.login1.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/default \
		templates/etc/default/nfs-common \
		templates/etc/default/nfs-common-userprincipal

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/polkit-1/localauthority/50-local.d \
		templates/etc/polkit-1/localauthority/50-local.d/90.org.freedesktop.networkmanager.deny_in_webkiosk_mode.pkla

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/racoon \
		templates/etc/racoon/racoon.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/samba \
		templates/etc/samba/smb.conf-laptop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sssd \
		templates/etc/sssd/sssd.conf \
		templates/etc/sssd/sssd.conf-laptop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sudoers.d \
		templates/etc/sudoers.d/puavo-install-when-preinstalled

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/systemd \
		templates/etc/systemd/logind.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/xdg/autostart \
		templates/etc/xdg/autostart/puavo-install.desktop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/usr/share/X11/xorg.conf.d \
		templates/usr/share/X11/xorg.conf.d/99-hitachicalib.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/var/lib/polkit-1/localauthority/10-vendor.d \
		templates/var/lib/polkit-1/localauthority/10-vendor.d/com.ubuntu.desktop.pkla

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/xsessions \
		xsessions/*

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/xsessions \
		xsessions/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-pulseaudio-setup \
		puavo-pulseaudio-list \
		puavo-remote-assistance-applet

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-configure-client \
		puavo-dnssd-printer-client \
		puavo-handle-external-files-actions \
		puavo-ltsp-login \
		puavo-netboot-init-nfs \
		puavo-report-system-version \
		puavo-update-nm-configurations

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-remote-assistance-applet.mo

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-remote-assistance-applet \
		etc/puavo-remote-assistance-applet/config.json

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/route-up \
		etc/puavo-vpn-client/scripts/route-up/10-dnsmasq \
		etc/puavo-vpn-client/scripts/route-up/20-sssd \
		etc/puavo-vpn-client/scripts/route-up/30-ntpdate

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/NetworkManager/dispatcher.d \
		etc/NetworkManager/dispatcher.d/dnssd-printers

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		etc/xdg/autostart/*

	$(INSTALL_DATA) -t $(DESTDIR)/lib/udev/rules.d \
		udev/rules.d/80-puavo-printers.rules \
		udev/rules.d/95-monitor-hotplug.rules

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/X11/Xsession.d \
		etc/X11/Xsession.d/41puavo-set-locale \
		etc/X11/Xsession.d/42puavo-set-browser-homepage \
		etc/X11/Xsession.d/43puavo-set-guest-session-quirks \
		etc/X11/Xsession.d/44puavo-generate-dconf-profile \
		etc/X11/Xsession.d/45puavo-display-setup \
		etc/X11/Xsession.d/47puavo-force-plaintext-keyring \
		etc/X11/Xsession.d/47puavo-set-default-browser-in-panel \
		etc/X11/Xsession.d/90puavo-setup-printers

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client \
		lib/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client/pam \
		pam/check-if-account-is-locked \
		pam/chown-session-dir \
		pam/make-session-dir \
		pam/open-session \
		pam/puavo-local-config-setup \
		pam/populate-extrausers \
		pam/restrict-logins-by-local-config \
		pam/setup-guest-session

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/xgreeters \
		xgreeters/puavo-gtk-greeter.desktop

	$(INSTALL_DATA) -t $(DESTDIR)/lib/systemd/system \
		systemd/*

	ln -fs -t $(DESTDIR)/lib/systemd/system/multi-user.target.wants \
		../puavo-darkdm.service

.PHONY : clean
clean :
	rm -rf po/fi/*.mo
	rm -rf po/*.pot
