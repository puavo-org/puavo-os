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
  # packages from the debian repositories
  #

  @package {
    [ 'cpufreqd'
    , 'elinks'
    , 'ethtool'
    , 'expect'
    , 'fping'
    , 'gawk'
    , 'git'
    , 'iftop'
    , 'initramfs-tools'
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
    , 'strace'
    , 'sudo'
    , 'sysstat'
    , 'tmux'
    , 'tshark'
    , 'w3m'
    , 'whois'
    , 'x11vnc'
    , 'xinput-calibrator' ]:
      tag => [ 'admin', 'thinclient', 'debian', ];

    [ 'clusterssh'
    , 'dconf-tools'
    , 'pssh'
    , 'smartmontools'
    , 'terminator'
    , 'vinagre'
    , 'xbacklight' ]:
      tag => [ 'admin', 'debian', ];

    [ 'libasound2-plugins'
    , 'mumble'
    , 'pavucontrol'
    , 'pavumeter'
    , 'pulseaudio-esound-compat'
    , 'timidity' ]:
      tag => [ 'audio', 'debian', ];

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
    , 'ubuntu-standard'
    , 'udev'
    , 'vlan' ]:
      tag => [ 'basic', 'debian', ];

    [ 'compizconfig-settings-manager'
    , 'compiz-plugins-extra'
    , 'indicator-power'
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
      tag => [ 'desktop', 'debian', ];

    [ 'ubuntu-restricted-addons' ]:
      tag => [ 'desktop', 'restricted', 'debian', ];

    [ 'acct'
    , 'ack-grep'
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
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'devel', 'debian', ];

    # [ 'bcmwl-kernel-source'	# XXX missing from Debian
    [ 'dkms'
    , 'firmware-b43-installer'
    , 'libgl1-mesa-glx'
    , 'linux-firmware'
    , 'nvidia-304'
    , 'nvidia-settings'
    , 'r8168-dkms'
    , 'xserver-xorg-video-all' ]:
      tag => [ 'drivers', 'debian', ];

    [ 'mutt' ]:
      tag => [ 'email', 'debian', ];

    [ 'wine' ]:
      tag => [ 'emulation', 'debian', ];

    [ 'fontconfig'
    , 'ttf-freefont'
    , 'xfonts-utils' ]:
      tag => [ 'fonts', 'debian', ];

    # needs debconf seeds or such to set license accepted,
    # but package itself is okay
    [ 'ttf-mscorefonts-installer' ]:
      tag => [ 'fonts', 'debian', ];

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
    , 'gnubg'
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
      tag => [ 'games', 'debian', ];

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
      tag => [ 'gnome', 'debian', ];

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
    , 'krita'
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
    , 'pencil'
    , 'photofilmstrip'
    , 'pinta'
    , 'pitivi'
    , 'python-lxml'
    , 'sane-utils'
    , 'stopmotion'
    , 'synfig'
    , 'synfigstudio'
    , 'xsane'
    , 'xzoom' ]:
      tag => [ 'graphics', 'debian', ];

    [ 'kdump-tools' ]:
      tag => [ 'kernelutils', 'debian', ];

    [ 'emesene'
    , 'gobby'
    , 'irssi'
    , 'irssi-plugin-xmpp'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack'
    , 'sflphone-gnome'
    , 'xchat' ]:
      tag => [ 'instant_messaging', 'debian', ];

    [ 'laptop-mode-tools' ]:
      tag => [ 'laptop', 'debian', ];

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
      tag => [ 'mediaplayer', 'debian', ];

    [ 'ltsp-client'
    , 'ltsp-server' ]:
        tag => [ 'misc', 'debian', ];

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
      tag => [ 'music_making', 'debian', ];

    [ 'amtterm'
    , 'ipsec-tools'
    , 'racoon'
    , 'wsmancli' ]:
      tag => [ 'network', 'debian', ];

    [ 'calibre'
    , 'fbreader'
    , 'librecad'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'scribus'
    , 'scribus-doc'
    , 'tellico'
    , 'thunderbird'
    , 'vym' ]:
      tag => [ 'office', 'debian', ];

    [ 'cdparanoia'
    , 'cdrdao'
    , 'cue2toc'
    , 'eject'
    , 'rhythmbox-plugin-cdrecorder'
    , 'sound-juicer' ]:
      tag => [ 'optical_media', 'debian', ];

    [ 'gtklp' ]:
      tag => [ 'printing', 'debian', ];

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
    , 'idle-python2.7'
    , 'idle-python3.4'
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
      tag => [ 'programming', 'debian', ];

    [ 'gftp-gtk'
    , 'libmotif4'	# required by icaclient
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'unison-gtk'
    , 'wget'
    , 'xtightvncviewer']:
      tag => [ 'remote_access', 'debian', ];

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
    , 'mandelbulber'
    , 'marble-qt'
    , 'pspp'
    , 'qgis'
    , 'rkward'
    , 'stellarium'
    , 'texlive-fonts-extra'
    , 'texlive-fonts-recommended'
    , 'texlive-latex-extra'
    , 'texlive-latex-recommended'
    , 'wxmaxima' ]:
      tag => [ 'science', 'debian', ];

    [ 'ubuntu-mono' ]:
      tag => [ 'themes', 'thinclient', 'debian', ];

    [ 'breathe-icon-theme'
    , 'gnome-icon-theme'
    , 'gnome-themes-extras'
    , 'gnome-themes-ubuntu'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    , 'human-theme'
    , 'light-themes'
    , 'openclipart'
    , 'oxygen-icon-theme'
    , 'pidgin-themes'
    , 'screensaver-default-images'
    , 'tangerine-icon-theme'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'debian', ];

    [ 'debian-edu-artwork'
    , 'debian-edu-artwork-joy'
    , 'debian-edu-artwork-lines'
    , 'debian-edu-artwork-spacefun' ]:
      tag => [ 'backgroundimages', 'themes', 'debian', 'jessie', ];

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
    # , 'compiz'				# XXX missing from Debian
    , 'cups'
    , 'cups-bsd'
    , 'cups-client'
    , 'cups-filters'
    , 'dconf-editor'
    # , 'deja-dup'				# not needed
    # , 'deja-dup-backend-cloudfiles'
    # , 'deja-dup-backend-gvfs'
    # , 'deja-dup-backend-s3'
    , 'empathy'
    , 'eog'
    , 'evince'
    , 'evolution'
    , 'file-roller'
    , 'fonts-cantarell'
    , 'fonts-dejavu-core'
    , 'fonts-droid'
    , 'fonts-freefont-ttf'
    , 'fonts-guru'
    , 'fonts-kacst-one'
    , 'fonts-khmeros-core'
    , 'fonts-lao'
    , 'fonts-liberation'
    , 'fonts-lklug-sinhala'
    , 'fonts-nanum'
    , 'fonts-sil-abyssinica'
    , 'fonts-sil-padauk'
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
    , 'gnome-shell'
    , 'gnome-shell-extensions'
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
    , 'gvfs-bin'
    , 'gvfs-fuse'
    , 'hplip'
    , 'i3'
    , 'ibus'
    , 'ibus-gtk3'
    , 'ibus-pinyin'
    , 'ibus-table'
    , 'iceweasel'
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
    , 'rtmpdump'
    , 'rxvt-unicode'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    , 'software-center'
    # , 'software-properties-gtk'		# (purged elsewhere)
    , 'speech-dispatcher'
    , 'ssh-askpass-gnome'
    , 'telepathy-idle'
    , 'totem'
    # , 'tracker'				# (purged elsewhere)
    , 'transmission-gtk'
    , 'ubuntu-extras-keyring'
    , 'ubuntu-gnome-default-settings'
    , 'ubuntu-gnome-wallpapers'
    # , 'ubuntu-release-upgrader-gtk'		# (purged elsewhere)
    , 'unzip'
    # , 'update-manager'			# (purged elsewhere)
    # , 'update-notifier'			# (purged elsewhere)
    # , 'usb-creator-gtk'			# XXX missing from Debian
    , 'vino'
    , 'wireless-tools'
    , 'wpasupplicant'
    , 'xdg-user-dirs'
    , 'xdg-user-dirs-gtk'
    , 'xdg-utils'
    , 'xfce4'
    , 'xkb-data'
    , 'xorg'
    , 'xterm'
    , 'xul-ext-ubufox'
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'youtube-dl'
    , 'zenity'
    , 'zip'
    , 'zsync' ]:
      tag => [ 'ubuntu-gnome-desktop', 'debian', ];

    [ 'bindfs'
    , 'desktop-file-utils'
    , 'devilspie'
    , 'duplicity'
    , 'exfat-fuse'
    , 'exfat-utils'
    , 'fuse'
    , 'gconf-editor'
    , 'ginn'
    , 'gkbd-capplet'
    , 'gpointing-device-settings'
    , 'ibus-libpinyin'
    , 'kdepasswd'
    , 'keepass2'
    , 'keepassx'
    , 'keychain'
    , 'khelpcenter4'
    , 'password-gorilla'
    , 'rarian-compat'
    , 'screenlets'
    , 'touchegg'
    , 'unace'
    , 'unionfs-fuse'
    , 'unrar'
    , 'x-tile' ]:
      tag => [ 'utils', 'debian', ];

    [ 'qemu-kvm' ]:
      tag => [ 'virtualization', 'debian', ];

    [ 'bluefish'
    , 'browser-plugin-vlc'
    , 'chromium-browser'
    , 'epiphany-browser'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-7-jdk'
    , 'openjdk-7-jre'
    , 'php5-cli'
    , 'php5-sqlite'
    , 'sqlite3' ]:
      tag => [ 'web', 'debian', ];
  }

  #
  # packages from the (Opinsys) puavo repository
  #

  @package {
    [ 'nodejs-bundle'
    , 'puavo-rules'
    , 'puavo-devscripts' ]:
      tag => [ 'devel', 'puavo', ];

    # XXX not yet packaged for Debian (except ltsp-client)
    # [ 'autopoweroff'
    # , 'ltsp-client'
    # , 'opinsys-ca-certificates'
    # , 'puavo-autopilot'
    # , 'puavo-client'
    # , 'puavo-hw-log'
    # , 'puavo-ltsp-client'
    # , 'puavo-ltsp-install'
    # , 'puavo-monitor'
    # , 'puavo-vpn-client' ]:
    #   tag => [ 'misc', 'puavo', 'thinclient', ];

    # XXX needs packaging for Debian
    # [ 'fluent-plugin-puavo'
    # , 'iivari-client'
    # , 'puavo-image-tools'
    # , 'puavo-load-reporter'
    # , 'puavo-local-config'
    # , 'puavo-pkg'
    # , 'puavo-sharedir-client'
    # , 'puavo-wlanap'
    # , 'simplescreenrecorder' ]:
    # , 'webmenu'
    # , 'webkiosk-language-selector'
    # , 'xexit' ]:
    #   tag => [ 'misc', 'puavo', ];

    [ 'dymo-cups-drivers' ]:
      tag => [ 'printing', 'puavo', ];

    # [ 'bluegriffon'	# XXX missing from Debian
    [ 'enchanting'
    , 'pycharm'
    , 'snap4arduino' ]:
      tag => [ 'programming', 'puavo', ];

    [ 'x2goclient'
    , 'x2goserver' ]:
      tag => [ 'remote_access', 'puavo', ];

    [ 'faenza-icon-theme' ]:
      tag => [ 'themes', 'puavo', ];

    # [ 'node-webkit'
    [ 'xul-ext-flashblock' ]:
      tag => [ 'web', 'puavo', ];
  }

  $bcmwl_dkms_module  = 'bcmwl/6.30.223.248+bdcom'
  $nvidia_dkms_module = 'nvidia-304/304.128'
  $r8168_dkms_module  = 'r8168/8.040.00'
  $all_dkms_modules   = [ $nvidia_dkms_module, $r8168_dkms_module ]
			# $bcmwl_dkms_module	# XXX missing from Debian

  case $lsbdistcodename {
    'jessie': {
      packages::kernels::kernel_package {
        '3.16.0-4-amd64':
          dkms_modules => $all_dkms_modules;
      }
    }
  }

  #
  # packages from the canonical/ubuntu partner repository
  #

  @package {
    # XXX missing from Debian
    # [ 'skype' ]:
    #   tag => [ 'instant_messaging', 'partner', 'extra', 'restricted' ];

    # XXX missing from Debian
    # [ 'vmware-view-client' ]:
    #   tag => [ 'remote_access', 'partner', 'restricted' ];

    [ 'adobe-flashplugin' ]:
      tag => [ 'web', 'partner', 'extra', 'restricted' ];
  }

  # Packages which are not restricted per se, but which are required by
  # restricted packages. These need to be installed and distributed in
  # the image to minimize the effort of installing restricted packages
  # "during runtime".
  @package {
    [ 'libnspr4-0d' # spotify
    , 'lsb-core' ]: # google-earth
      tag => [ 'debian', 'required-by-restricted' ];
  }
}
