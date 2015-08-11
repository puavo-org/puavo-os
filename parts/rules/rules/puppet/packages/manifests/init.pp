class packages {
  require apt::default_repositories,
          apt::multiarch,
          opinsys_apt_repositories,
          packages::proposed_updates

  include packages::kernels,
	  packages::purged

  # install packages by default
  Package { ensure => present, }

  #
  # packages from the ubuntu repositories
  #

  @package {
    [ 'elinks'
    , 'ethtool'
    , 'cpufreqd'
    , 'fping'
    , 'gawk'
    , 'git'
    , 'initramfs-tools'
    , 'iftop'
    , 'inotify-tools'
    , 'iperf'
    , 'libstdc++5'
    , 'lm-sensors'
    , 'lshw'
    , 'lynx'
    , 'm4'
    , 'mlocate'
    , 'moreutils'
    , 'nmap'
    , 'powertop'
    , 'pv'
    , 'pwgen'
    , 'pwman3'
    , 'screen'
    , 'setserial'
    , 'sl'
    , 'strace'
    , 'sudo'
    , 'sysstat'
    , 'tmux'
    , 'tshark'
    , 'whois'
    , 'w3m'
    , 'x11vnc'
    , 'xinput-calibrator' ]:
      tag => [ 'admin', 'thinclient', 'ubuntu', ];

    [ 'clusterssh'
    , 'dconf-tools'
    , 'pssh'
    , 'terminator'
    , 'vinagre'
    , 'xbacklight' ]:
      tag => [ 'admin', 'ubuntu', ];

    [ 'libasound2-plugins'
    , 'pavucontrol'
    , 'pavumeter'
    , 'pulseaudio-esound-compat'
    , 'timidity' ]:
      tag => [ 'audio', 'ubuntu', ];

    [ 'bash'
    , 'bridge-utils'
    , 'gdebi-core'
    , 'grub-pc'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'policykit-1'
    , 'pm-utils'
    , 'rng-tools'
    , 'udev'
    , 'ubuntu-standard'
    , 'vlan' ]:
      tag => [ 'basic', 'ubuntu', ];

    [ 'indicator-power'
    , 'indicator-session'
    , 'lightdm'
    , 'lightdm-gtk-greeter'
    , 'lsb-invalid-mta'
    , 'network-manager-openvpn-gnome'
    , 'notify-osd'
    , 'onboard'
    , 'overlay-scrollbar'               # needed by accessibility stuff
    , 'python-appindicator'
    , 'python-gtk2'
    , 'python-notify'
    , 'shared-mime-info'
    , 'xul-ext-mozvoikko' ]:
      tag => [ 'desktop', 'ubuntu', ];

    [ 'ubuntu-restricted-addons'
    , 'ubuntu-restricted-extras' ]:
      tag => [ 'desktop', 'restricted', 'ubuntu', ];

    [ 'ack-grep'
    , 'acct'
    , 'build-essential'
    , 'bvi'
    , 'cdbs'
    , 'debconf-doc'
    , 'devscripts'
    , 'dh-make'
    , 'dpkg-dev'
    , 'fakeroot'
    , 'gdb'
    , 'gnupg'
    , 'libssl-dev'
    , 'manpages-dev'
    , 'perl-doc'
    , 'pinfo'
    , 'unetbootin'
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'devel', 'ubuntu', ];

    [ 'bcmwl-kernel-source'
    , 'firmware-b43-installer'
    , 'libgl1-mesa-glx'
    , 'linux-firmware'
    , 'nvidia-304'
    , 'nvidia-settings'
    , 'xserver-xorg-video-all' ]:
      tag => [ 'drivers', 'ubuntu', ];

    [ 'mutt' ]:
      tag => [ 'email', 'ubuntu', ];

    [ 'wine' ]:
      tag => [ 'emulation', 'ubuntu', ];

    [ 'ttf-freefont' ]:
      tag => [ 'fonts', 'ubuntu', ];

    # needs debconf seeds or such to set license accepted,
    # but package itself is okay
    [ 'ttf-mscorefonts-installer' ]:
      tag => [ 'fonts', 'ubuntu', ];

    [ 'billard-gl'
    , 'cuyo'
    , 'dosbox'
    , 'extremetuxracer'
    , 'freeciv-client-gtk'
    , 'frozen-bubble'
    , 'gbrainy'
    , 'gcompris'
    , 'gcompris-sound-en'
    , 'gcompris-sound-fi'
    , 'gcompris-sound-sv'
    , 'gnibbles'
    , 'gnotski'
    , 'gnuchess'
    , 'icebreaker'
    , 'kanagram'
    , 'kdeedu'
    , 'khangman'
    , 'kolf'
    , 'ktouch'
    , 'ktuberling'
    , 'kwordquiz'
    , 'laby'
    , 'lincity-ng'
    , 'luola'
    , 'neverball'
    , 'neverputt'
    , 'openttd'
    , 'pacman'
    , 'pingus'
    , 'realtimebattle'
    , 'sgt-puzzles'
    , 'supertuxkart'
    , 'tuxmath'
    , 'tuxpaint'
    , 'tuxpaint-stamps-default'
    , 'warmux'
    , 'xmoto' ]:
      tag => [ 'games', 'ubuntu', ];

    [ 'consolekit'
    , 'dbus-x11'
    , 'gnome-applets'
    , 'gnome-power-manager'
    , 'gnome-user-guide'
    , 'libgnome2-perl'
    , 'libgnomevfs2-bin'
    , 'libgnomevfs2-extra'

    # needed by (gnome|unity)-control-center accessibility settings
    , 'libunity-core-6.0-9'

    , 'notification-daemon'
    , 'thunderbird-gnome-support'
    , 'ubuntu-docs' ]:
      tag => [ 'gnome', 'ubuntu', ];

    [ 'blender'
    , 'dia'
    , 'dvgrab'
    , 'f-spot'
    , 'gimp'
    , 'gimp-data-extras'
    , 'gimp-gap'
    , 'gimp-plugin-registry'
    , 'gimp-ufraw'
    , 'gocr'
    , 'gthumb'
    , 'gtkam'
    , 'hugin'
    , 'inkscape'
    , 'jhead'
    , 'kdenlive'
    , 'kino'
    , 'kolourpaint4'
    , 'libav-tools'
    , 'libsane'
    , 'libsane-extras'
    , 'luciole'
    , 'mencoder'
    , 'mjpegtools'
    , 'mypaint'
    , 'nautilus-image-converter'
    , 'okular'
    , 'openshot'
    , 'photofilmstrip'
    , 'pencil'
    , 'pinta'
    , 'pitivi'
    , 'python-lxml'
    , 'sane-utils'
    , 'stopmotion'
    , 'synfig'
    , 'synfigstudio'
    , 'xsane'
    , 'xzoom' ]:
      tag => [ 'graphics', 'ubuntu', ];

    [ 'kdump-tools' ]:
      tag => [ 'kernelutils', 'ubuntu', ];

    [ 'emesene'
    , 'gobby'
    , 'irssi'
    , 'irssi-plugin-xmpp'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack'
    , 'sflphone-gnome'
    , 'xchat' ]:
      tag => [ 'instant_messaging', 'ubuntu', ];

    # de - German packages

    [ 'language-pack-gnome-de' ]:
      tag => [ 'language-de', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-de'
    , 'gimp-help-de'
    , 'hyphen-de'
    , 'kde-l10n-de'
    , 'language-pack-kde-de'
    , 'language-pack-de'
    , 'libreoffice-help-de'
    , 'libreoffice-l10n-de'
    , 'myspell-de-ch'
    , 'myspell-de-de'
    , 'mythes-de'
    , 'mythes-de-ch'
    , 'thunderbird-locale-de' ]:
      tag => [ 'language-de', 'ubuntu', ];

    # en - English packages

    [ 'language-pack-gnome-en' ]:
      tag => [ 'language-en', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-en'
    , 'hyphen-en-us'
    , 'kde-l10n-engb'
    , 'language-pack-en'
    , 'language-pack-kde-en'
    , 'libreoffice-help-en-gb'
    , 'libreoffice-l10n-en-gb'
    , 'libreoffice-l10n-en-za'
    , 'myspell-en-gb'
    , 'mythes-en-us'
    , 'thunderbird-locale-en-gb' ]:
      tag => [ 'language-en', 'ubuntu', ];

    # fi - Finnish packages

    [ 'language-pack-gnome-fi' ]:
      tag => [ 'language-fi', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-fi'
    , 'kde-l10n-fi'
    , 'language-pack-fi'
    , 'language-pack-kde-fi'
    , 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko'
    , 'thunderbird-locale-fi' ]:
      tag => [ 'language-fi', 'ubuntu', ];

    # fr - French packages

    [ 'language-pack-gnome-fr' ]:
      tag => [ 'language-fr', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-fr'
    , 'gimp-help-fr'
    , 'hyphen-fr'
    , 'kde-l10n-fr'
    , 'language-pack-fr'
    , 'language-pack-kde-fr'
    , 'libreoffice-help-fr'
    , 'libreoffice-l10n-fr'
    , 'myspell-fr'
    , 'mythes-fr'
    , 'thunderbird-locale-fr' ]:
      tag => [ 'language-sv', 'ubuntu', ];

    # sv - Swedish packages

    [ 'language-pack-gnome-sv' ]:
      tag => [ 'language-sv', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-sv'
    , 'gimp-help-sv'
    , 'kde-l10n-sv'
    , 'language-pack-kde-sv'
    , 'language-pack-sv'
    , 'libreoffice-help-sv'
    , 'libreoffice-l10n-sv'
    , 'myspell-sv-se'
    , 'mythes-sv'
    , 'thunderbird-locale-sv' ]:
      tag => [ 'language-sv', 'ubuntu', ];

    [ 'laptop-mode-tools' ]:
      tag => [ 'laptop', 'ubuntu', ];

    [ 'banshee'
    , 'clam-chordata'
    , 'gnome-mplayer'
    , 'goobox'
    , 'gstreamer1.0-clutter'
    , 'gstreamer1.0-libav'
    , 'gstreamer1.0-plugins-bad'
    , 'gstreamer1.0-plugins-base'
    , 'gstreamer1.0-plugins-good'
    , 'gstreamer1.0-plugins-ugly'
    , 'gstreamer1.0-tools'
    , 'gtk-recordmydesktop'
    , 'kaffeine'
    , 'kscd'
    , 'libdvdread4'
    , 'me-tv'
    , 'ogmrip'
    , 'python-gst0.10'
    , 'vlc'
    , 'vlc-plugin-pulse'
    , 'x264'
    , 'xbmc' ]:
      tag => [ 'mediaplayer', 'ubuntu', ];

    [ 'ardour'
    , 'audacity'
    , 'denemo'
    , 'fmit'
    , 'hydrogen'
    , 'lmms'
    , 'mixxx'
    , 'musescore'
    , 'musescore-soundfont-gm'
    , 'qsynth'
    , 'rakarrack'
    , 'rosegarden'
    , 'solfege'
    , 'soundconverter'
    , 'sweep'
    , 'tuxguitar'
    , 'tuxguitar-jsa' ]:
      tag => [ 'music_making', 'ubuntu', ];

    [ 'ipsec-tools'
    , 'amtterm'
    , 'wsmancli'
    , 'racoon' ]:
      tag => [ 'network', 'ubuntu', ];

    [ 'calibre'
    , 'fbreader'
    , 'librecad'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'libreoffice-common'
    , 'scribus'
    , 'scribus-doc'
    , 'tellico'
    , 'thunderbird'
    , 'vym' ]:
      tag => [ 'office', 'ubuntu', ];

    [ 'cdparanoia'
    , 'cdrdao'
    , 'cue2toc'
    , 'eject'
    , 'rhythmbox-plugin-cdrecorder'
    , 'sound-juicer' ]:
      tag => [ 'optical_media', 'ubuntu', ];

    [ 'arduino'
    , 'arduino-mk'
    , 'avr-libc'
    , 'basic256'
    , 'eclipse'
    , 'emacs24'
    , 'eric'
    , 'eric-api-files'
    , 'fritzing'
    , 'gcc-avr'
    , 'geany'
    , 'idle'
    , 'kompare'
    , 'kturtle'
    , 'lokalize'
    , 'pyqt4-dev-tools'
    , 'python-doc'
    , 'python-pygame'
    , 'python-renpy'
    , 'pythontracer'
    , 'qt4-designer'
    , 'qt4-doc'
    , 'racket'
    , 'renpy'
    , 'scratch'
    , 'spe' ]:
      tag => [ 'programming', 'ubuntu', ];

    [ 'gftp-gtk'
    , 'libmotif4'	# required by icaclient
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'unison-gtk'
    , 'wget'
    , 'xtightvncviewer']:
      tag => [ 'remote_access', 'ubuntu', ];

    [ 'atomix'
    , 'avogadro'
    , 'celestia'
    , 'celestia-common-nonfree'
    , 'celestia-gnome'
    , 'drgeo'
    , 'drgeo-doc'
    , 'gchempaint'
    , 'ghemical'
    , 'gnucap'
    , 'gnuplot'
    , 'gnuplot-x11'
    , 'gretl'
    , 'kalzium'
    , 'kbruch'
    , 'kgeography'
    , 'kig'
    , 'kmplot'
    , 'kstars'
    , 'marble-qt'
    , 'mandelbulber'
    , 'pspp'
    , 'qgis'
    , 'rkward'
    , 'stellarium'
    , 'texlive-fonts-extra'
    , 'texlive-fonts-recommended'
    , 'texlive-latex-extra'
    , 'texlive-latex-recommended'
    , 'wxmaxima' ]:
      tag => [ 'science', 'ubuntu', ];

    [ 'ubuntu-mono' ]:
      tag => [ 'themes', 'thinclient', 'ubuntu', ];

    [ 'breathe-icon-theme'
    , 'edubuntu-wallpapers'
    , 'gnome-icon-theme'
    , 'gnome-themes-ubuntu'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    , 'human-theme'
    , 'light-themes'
    , 'openclipart'
    , 'pidgin-themes'
    , 'tangerine-icon-theme'
    , 'screensaver-default-images'
    , 'ubuntu-wallpapers'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'ubuntu', ];

    [ 'ubuntu-wallpapers-precise' ]:
      tag => [ 'backgroundimages', 'themes', 'ubuntu', 'precise', 'trusty', ];

    [ 'ubuntu-wallpapers-quantal'
    , 'ubuntu-wallpapers-raring'
    , 'ubuntu-wallpapers-saucy'
    , 'ubuntu-wallpapers-trusty' ]:
      tag => [ 'backgroundimages', 'themes', 'ubuntu', 'trusty', ];

    # the dependencies (and recommends) of ubuntu-gnome-desktop package
    # without a few packages that we do not want
    [ 'acpi-support'
    , 'aisleriot'
    , 'alsa-base'
    , 'alsa-utils'
    , 'anacron'
    , 'app-install-data-partner'
    , 'apport-gtk'
    , 'at-spi2-core'
    , 'avahi-autoipd'
    , 'avahi-daemon'
    , 'baobab'
    , 'bc'
    , 'bluez'
    , 'bluez-alsa'
    , 'bluez-cups'
    , 'brasero'
    , 'brltty'
    , 'ca-certificates'
    , 'cheese'
    , 'compiz'
    , 'cups'
    , 'cups-bsd'
    , 'cups-client'
    , 'cups-filters'
    , 'dconf-editor'
    # , 'deja-dup'				# not needed
    # , 'deja-dup-backend-cloudfiles'
    # , 'deja-dup-backend-s3'
    , 'empathy'
    , 'eog'
    , 'evince'
    , 'evolution'
    , 'file-roller'
    , 'firefox'
    , 'fonts-cantarell'
    , 'fonts-dejavu-core'
    , 'fonts-droid'
    , 'fonts-freefont-ttf'
    , 'fonts-kacst-one'
    , 'fonts-khmeros-core'
    , 'fonts-lao'
    , 'fonts-liberation'
    , 'fonts-lklug-sinhala'
    , 'fonts-nanum'
    , 'fonts-sil-abyssinica'
    , 'fonts-sil-padauk'
    , 'fonts-takao-pgothic'
    , 'fonts-thai-tlwg'
    , 'fonts-tibetan-machine'
    , 'foomatic-db-compressed-ppds'
    , 'gcc'
    , 'gcr'
    # , 'gdm'					# not needed
    , 'gedit'
    , 'genisoimage'
    , 'ghostscript-x'
    , 'gjs'
    , 'gnome-accessibility-themes'
    , 'gnome-backgrounds'
    , 'gnome-bluetooth'
    , 'gnome-calculator'
    , 'gnome-color-manager'
    , 'gnome-contacts'
    , 'gnome-control-center'
    , 'gnome-disk-utility'
    # , 'gnome-documents'	# forces tracker to be installed
				# (tracker is purged elsewhere)
    , 'gnome-font-viewer'
    , 'gnome-icon-theme-extras'
    , 'gnome-icon-theme-full'
    , 'gnome-icon-theme-symbolic'
    , 'gnome-keyring'
    , 'gnome-mahjongg'
    , 'gnome-menus'
    , 'gnome-mines'
    , 'gnome-online-accounts'
    , 'gnome-orca'
    , 'gnome-screenshot'
    , 'gnome-session'
    , 'gnome-session-canberra'
    , 'gnome-settings-daemon'
    # , 'gnome-shell'				# not needed
    # , 'gnome-shell-extensions'
    , 'gnome-sudoku'
    , 'gnome-sushi'
    , 'gnome-system-log'
    , 'gnome-system-monitor'
    , 'gnome-terminal'
    , 'gnome-themes-standard'
    , 'gnome-tweak-tool'
    , 'gnome-user-share'
    , 'gnome-video-effects'
    , 'gsettings-desktop-schemas'
    , 'gstreamer0.10-alsa'
    , 'gstreamer0.10-pulseaudio'
    , 'gstreamer1.0-alsa'
    , 'gstreamer1.0-pulseaudio'
    , 'gucharmap'
    , 'gvfs-backends-goa'
    , 'gvfs-bin'
    , 'gvfs-fuse'
    , 'hplip'
    , 'i3'
    , 'ibus'
    , 'ibus-gtk3'
    , 'ibus-pinyin'
    , 'ibus-table'
    , 'inputattach'
    , 'itstool'
    , 'kerneloops-daemon'
    , 'laptop-detect'
    , 'libatk-adaptor'
    , 'libgail-common'
    , 'libnotify-bin'
    , 'libnss-mdns'
    , 'libnss-myhostname'
    , 'libpam-gnome-keyring'
    , 'libpam-systemd'
    , 'libproxy1-plugin-gsettings'
    , 'libproxy1-plugin-networkmanager'
    , 'libreoffice-calc'
    , 'libreoffice-gnome'
    , 'libreoffice-impress'
    , 'libreoffice-math'
    , 'libreoffice-ogltrans'
    , 'libreoffice-pdfimport'
    , 'libreoffice-presentation-minimizer'
    , 'libreoffice-style-tango'
    , 'libreoffice-writer'
    , 'libsasl2-modules'
    , 'libwmf0.2-7-gtk'
    , 'libxp6'
    , 'make'
    , 'mcp-account-manager-goa'
    , 'memtest86+'
    , 'mousetweaks'
    , 'mutter'
    , 'nautilus'
    , 'nautilus-sendto'
    # , 'nautilus-share' # forces software-properties-gtk to be installed
    , 'network-manager'
    , 'network-manager-pptp'
    , 'network-manager-pptp-gnome'
    , 'openprinting-ppds'
    , 'pcmciautils'
    # , 'plymouth-theme-ubuntu-gnome-logo'	# not needed
    # , 'plymouth-theme-ubuntu-gnome-text'	# not needed
    , 'policykit-desktop-privileges'
    , 'printer-driver-c2esp'
    , 'printer-driver-foo2zjs'
    , 'printer-driver-min12xxw'
    , 'printer-driver-pnm2ppa'
    , 'printer-driver-ptouch'
    , 'printer-driver-pxljr'
    , 'printer-driver-sag-gdi'
    , 'printer-driver-splix'
    , 'pulseaudio'
    , 'pulseaudio-module-bluetooth'
    , 'pulseaudio-module-x11'
    , 'python3-aptdaemon.pkcompat'
    , 'rfkill'
    , 'rhythmbox'
    , 'rhythmbox-plugin-magnatune'
    , 'rtmpdump'
    , 'rxvt-unicode'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    , 'software-center'
    # , 'software-properties-gtk'		# (purged elsewhere)
    , 'speech-dispatcher'
    , 'ssh-askpass-gnome'
    , 'system-config-printer-gnome'
    , 'telepathy-idle'
    , 'totem'
    # , 'tracker'				# (purged elsewhere)
    , 'transmission-gtk'
    , 'ttf-indic-fonts-core'
    , 'ttf-punjabi-fonts'
    , 'ttf-ubuntu-font-family'
    , 'ubuntu-drivers-common'
    , 'ubuntu-extras-keyring'
    , 'ubuntu-gnome-default-settings'
    , 'ubuntu-gnome-wallpapers'
    # , 'ubuntu-release-upgrader-gtk'		# (purged elsewhere)
    , 'unzip'
    # , 'update-manager'			# (purged elsewhere)
    # , 'update-notifier'			# (purged elsewhere)
    , 'usb-creator-gtk'
    , 'vino'
    , 'whoopsie'
    , 'wireless-tools'
    , 'wpasupplicant'
    , 'xdg-user-dirs'
    , 'xdg-user-dirs-gtk'
    , 'xdg-utils'
    , 'xdiagnose'
    , 'xfce4'
    , 'xkb-data'
    , 'xorg'
    , 'xterm'
    , 'xul-ext-ubufox'
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'zenity'
    , 'zip'
    , 'zsync' ]:
      tag => [ 'ubuntu-gnome-desktop', 'ubuntu', ];

    [ 'bindfs'
    , 'desktop-file-utils'
    , 'devilspie'
    , 'exfat-fuse'
    , 'exfat-utils'
    , 'fuse'
    , 'gconf-editor'
    , 'gkbd-capplet'
    , 'gpointing-device-settings'
    , 'kdepasswd'
    , 'keepass2'
    , 'keepassx'
    , 'keychain'
    , 'khelpcenter4'
    , 'rarian-compat'
    , 'screenlets'
    , 'unace'
    , 'unionfs-fuse'
    , 'unrar' ]:
      tag => [ 'utils', 'ubuntu', ];

    [ 'qemu-kvm' ]:
      tag => [ 'virtualization', 'ubuntu', ];

    [ 'bluefish'
    , 'browser-plugin-vlc'
    , 'chromium-browser'
    , 'epiphany-browser'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-6-jdk'
    , 'openjdk-6-jre'
    , 'php5-cli'
    , 'php5-sqlite'
    , 'sqlite3' ]:
      tag => [ 'web', 'ubuntu', ];
  }

  #
  # packages from the (Opinsys) puavo repository
  #

  @package {
    [ 'nodejs-bundle'
    , 'puavo-rules'
    , 'puavo-devscripts' ]:
      tag => [ 'devel', 'puavo', ];

    [ 'autopoweroff'
    , 'ltsp-client'
    , 'opinsys-ca-certificates'
    , 'puavo-autopilot'
    , 'puavo-client'
    , 'puavo-hw-log'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-monitor'
    , 'puavo-vpn-client' ]:
      tag => [ 'misc', 'puavo', 'thinclient', ];

    [ 'fluent-plugin-puavo'
    , 'iivari-client'
    , 'ltsp-server'
    , 'puavo-image-tools'
    , 'puavo-load-reporter'
    , 'puavo-local-config'
    , 'puavo-pkg'
    , 'puavo-sharedir-client'
    , 'puavo-wlanap'
    , 'puavo-wlanap-dnsproxy'
    , 'simplescreenrecorder'
    , 'webmenu'
    , 'webkiosk-language-selector'
    , 'xexit' ]:
      tag => [ 'misc', 'puavo', ];

    [ 'dymo-cups-drivers' ]:
      tag => [ 'printing', 'puavo', ];

    [ 'bluegriffon'
    , 'enchanting'
    , 'pycharm'
    , 'snap4arduino' ]:
      tag => [ 'programming', 'puavo', ];

    [ 'x2goclient'
    , 'x2goserver' ]:
      tag => [ 'remote_access', 'puavo', ];

    [ 'faenza-icon-theme' ]:
      tag => [ 'themes', 'puavo', ];

    [ 'node-webkit'
    , 'xul-ext-flashblock' ]:
      tag => [ 'web', 'puavo', ];
  }

  case $lsbdistcodename {
    'precise': {
      packages::kernels::kernel_package {
        '3.2.0-69-generic':
          package_tag => 'puavo',
          with_extra  => false;
      }
    }
    'trusty': {
      if $architecture == 'i386' {
        packages::kernels::kernel_package {
          [ '3.2.0-70-generic-pae', '4.0.6.opinsys3', ]:
            package_tag => 'puavo',
            with_extra  => false;

          [ '3.13.0-46-generic' ]:
            pkgarch => 'amd64';
        }
      }

      packages::kernels::kernel_package {
        [ '3.13.0-55.94-generic', ]:
          package_tag => 'puavo';

        [ '3.16.0-38-generic', ]: ; # utopic backport from Ubuntu
        [ '3.19.0-18-generic', ]: ; # vivid backport from Ubuntu
      }
    }
    'utopic': {
      packages::kernels::kernel_package {
        '3.16.0-38-generic':
          package_tag => 'puavo';
      }
    }
    'vivid': {
      packages::kernels::kernel_package {
        '3.19.0-18-generic':
          package_tag => 'puavo';
      }
    }
  }

  #
  # packages from the canonical/ubuntu partner repository
  #

  @package {
    [ 'skype' ]:
      tag => [ 'instant_messaging', 'partner', 'extra', 'restricted' ];

    [ 'vmware-view-client' ]:
      tag => [ 'remote_access', 'partner', 'restricted' ];

    [ 'adobe-flashplugin' ]:
      tag => [ 'web', 'partner', 'extra', 'restricted' ];
  }

  # Packages which are not restricted per se, but which are required by
  # restricted packages. These need to be installed and distributed in
  # the image to minimize the effort of installing restricted packages
  # "during runtime".
  @package {
    [ 'libnspr4-0d' # spotify
    , 'libssl0.9.8' # spotify
    , 'lsb-core' ]: # google-earth
      tag => [ 'ubuntu', 'required-by-restricted' ];

    [ 'libudev0' ]: # spotify
      tag => [ 'puavo', 'required-by-restricted' ];
  }
}
