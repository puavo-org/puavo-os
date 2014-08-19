class packages {
  require apt::repositories,
          organisation_apt_repositories

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
    , 'lynx'
    , 'm4'
    , 'mlocate'
    , 'nmap'
    , 'powertop'
    , 'pv'
    , 'pwgen'
    , 'pwman3'
    , 'setserial'
    , 'sl'
    , 'strace'
    , 'sudo'
    , 'tmux'
    , 'tshark'
    , 'whois'
    , 'w3m'
    , 'x11vnc' ]:
      tag => [ 'admin', 'thinclient', 'ubuntu', ];

    [ 'clusterssh'
    , 'dconf-tools'
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
    , 'laptop-mode-tools'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'policykit-1'
    , 'pm-utils'
    , 'rng-tools'
    , 'udev'
    , 'vlan' ]:
      tag => [ 'basic', 'ubuntu', ];

    [ 'indicator-power'
    , 'indicator-session'
    , 'lightdm'
    , 'lightdm-gtk-greeter'
    , 'network-manager-openvpn-gnome'
    , 'notify-osd'
    , 'onboard'
    , 'overlay-scrollbar'               # needed by accessibility stuff
    , 'ubuntu-standard'
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
      tag => [ 'kernel', 'ubuntu', ];

    [ 'emesene'
    , 'gobby'
    , 'irssi'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack'
    , 'sflphone-gnome'
    , 'xchat' ]:
      tag => [ 'instant_messaging', 'ubuntu', ];

    [ 'language-pack-gnome-de' ]:
      tag => [ 'language-de', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-de'
    , 'gimp-help-de'
    , 'kde-l10n-de'
    , 'language-pack-kde-de'
    , 'language-pack-de'
    , 'libreoffice-help-de'
    , 'libreoffice-l10n-de'
    , 'myspell-de-ch'
    , 'myspell-de-de'
    , 'thunderbird-locale-de' ]:
      tag => [ 'language-de', 'ubuntu', ];

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
    , 'thunderbird-locale-sv' ]:
      tag => [ 'language-sv', 'ubuntu', ];

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
    , 'rosegarden'
    , 'solfege'
    , 'soundconverter'
    , 'sweep'
    , 'tuxguitar' ]:
      tag => [ 'music_making', 'ubuntu', ];

    [ 'ipsec-tools'
    , 'amtterm'
    , 'wsmancli'
    , 'racoon' ]:
      tag => [ 'network', 'ubuntu', ];

    [ 'librecad'
    , 'libreoffice'
    , 'libreoffice-base'
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
    , 'gcc-avr'
    , 'geany'
    , 'idle'
    , 'kompare'
    , 'kturtle'
    , 'lokalize'
    , 'netbeans'
    , 'pyqt4-dev-tools'
    , 'python-doc'
    , 'python-pygame'
    , 'pythontracer'
    , 'qt4-designer'
    , 'qt4-doc'
    , 'scratch'
    , 'spe' ]:
      tag => [ 'programming', 'ubuntu', ];

    [ 'gftp-gtk'
    , 'libmotif4'	# required by icaclient
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'unison-gtk'
    , 'wget' ]:
      tag => [ 'remote_access', 'ubuntu', ];

    [ 'atomix'
    , 'celestia'
    , 'celestia-common-nonfree'
    , 'celestia-gnome'
    , 'drgeo'
    , 'drgeo-doc'
    , 'gchempaint'
    , 'geogebra'
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
    , 'ubuntu-wallpapers-precise'
    , 'ubuntu-wallpapers-quantal'
    , 'ubuntu-wallpapers-raring'
    , 'ubuntu-wallpapers-saucy'
    , 'ubuntu-wallpapers-trusty'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'ubuntu', ];

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

    [ 'desktop-file-utils'
    , 'fuse'
    , 'gconf-editor'
    , 'gkbd-capplet'
    , 'gpointing-device-settings'
    , 'kdepasswd'
    , 'keychain'
    , 'khelpcenter4'
    , 'rarian-compat'
    , 'screenlets'
    , 'unace'
    , 'unrar' ]:
      tag => [ 'utils', 'ubuntu', ];

    [ 'qemu-kvm' ]:
      tag => [ 'virtualization', 'ubuntu', ];

    [ 'bluefish'
    , 'chromium-browser'
    , 'gecko-mediaplayer'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-6-jdk'
    , 'openjdk-6-jre' ]:
      tag => [ 'web', 'ubuntu', ];
  }

  #
  # packages from the opinsys/puavo repository
  #

  @package {
    [ 'nodejs-bundle'
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

    [ 'iivari-client'
    , 'ltsp-server'
    , 'puavo-load-reporter'
    , 'puavo-local-config'
    , 'puavo-sharedir-client'
    , 'puavo-wlanap'
    , 'puavo-wlanap-dnsproxy'
    , 'webmenu'
    , 'xexit' ]:
      tag => [ 'misc', 'puavo', ];

    [ 'bluegriffon'
    , 'pycharm' ]:
      tag => [ 'programming', 'puavo', ];

    [ 'x2goclient'
    , 'x2goserver' ]:
      tag => [ 'remote_access', 'puavo', ];

    [ 'faenza-icon-theme' ]:
      tag => [ 'themes', 'puavo', ];

    [ 'xul-ext-flashblock' ]:
      tag => [ 'web', 'puavo', ];
  }

  case $lsbdistcodename {
    'trusty': {
      packages::kernels::kernel_package {
        '3.13.0-29-generic':
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

  #
  # packages from the (private) opinsys repository
  #

  @package {
    [ 'spotify-client'
    , 'spotify-client-qt' ]:
      tag => [ 'audio', 'opinsys', 'extra', 'restricted' ];

    [ 'esci-interpreter-perfection-v330'
    , 'iscan'
    , 'iscan-data' ]:
      tag => [ 'epson-scanner', 'opinsys', 'restricted' ];

    [ 'libdvdcss2'
    , 'pipelight-multi' ]:
      tag => [ 'mediaplayer', 'opinsys', ];

    [ 'nautilus-dropbox' ]:
      tag => [ 'misc', 'opinsys', ];

    [ 'nautilus-dropbox-dist' ]:
      tag => [ 'misc', 'opinsys', 'extra', 'restricted' ];

    [ 'acroread'
    , 'cmaptools' ]:
      tag => [ 'office', 'opinsys', 'extra', 'restricted' ];

    [ 'icaclient' ]:
      # icaclient has a hidden dependency on libmotif4
      require => Package['libmotif4'],
      tag     => [ 'remote_access', 'opinsys', 'restricted' ];

    [ 'av4kav' ]:
      tag => [ 'science', 'opinsys', 'restricted' ];

    [ 'google-earth-stable'
    , 'googleearth' ]:
      tag => [ 'science', 'opinsys', 'extra', 'restricted' ];

    [ 'vstloggerpro' ]:
      tag => [ 'science', 'opinsys' ];

    [ 'opinsys-theme' ]:
      tag => [ 'themes', 'opinsys', ];

    [ 'google-talkplugin' ]:
      tag => [ 'web', 'opinsys', 'restricted' ];

    [ 'google-chrome-beta'
    , 'google-chrome-stable'
    , 'oracle-java' ]:
      tag => [ 'web', 'opinsys', 'extra', 'restricted' ];

    [ 'eleet'
    , 'leap' ]:
      tag => [ 'whiteboard', 'whiteboard-leapmotion', 'opinsys', 'restricted' ];

    [ 'ebeam-edu' ]:
      tag => [ 'whiteboard', 'whiteboard-ebeam', 'opinsys', 'restricted' ];

    [ 'mimio-studio' ]:
      tag => [ 'whiteboard', 'whiteboard-mimio', 'opinsys', 'restricted' ];

    # XXX this should not be here, but in a public repository:
    [ 'open-sankore', ]:
      tag => [ 'whiteboard', 'whiteboard-sankore', 'opinsys', ];

    [ 'nwfermi'
    , 'smart-activation'
    , 'smart-common'
    , 'smart-extreme-collaboration'
    , 'smart-galleryfiles'
    , 'smart-gallerysetup'
    , 'smart-hwr'
    , 'smart-languagesetup'
    , 'smart-notebook'
    , 'smart-product-drivers'
    , 'xf86-input-nextwindow' ]:
      tag => [ 'whiteboard', 'whiteboard-smartboard', 'opinsys', 'restricted' ];
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
