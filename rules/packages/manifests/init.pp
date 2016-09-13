class packages {
  require ::apt::multiarch
  include ::packages::purged

  # install packages by default
  Package { ensure => present, }

  #
  # Puavo OS packages
  #

  @package {
    [ 'iivari-client'
    , 'opinsys-ca-certificates'
    , 'puavo-autopilot'
    , 'puavo-blackboard'
    , 'puavo-client'
    , 'puavo-conf'
    , 'puavo-core'
    , 'puavo-devscripts'
    , 'puavo-hw-log'
    , 'puavo-hw-tools'
    , 'puavo-local-config'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-pkg'
    , 'puavo-sharedir-client'
    , 'puavo-vpn-client'
    , 'puavo-wlanap'
    , 'puavo-wlanmapper'
    , 'ruby-puavowlan'
    , 'webkiosk-language-selector'
    , 'webmenu' ]:
      ensure => present;
  }

  #
  # packages from the Debian repositories
  #

  @package {
    [ 'cpufreqd'
    , 'console-setup'
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
    , 'procps'
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
      tag => [ 'tag_admin', 'tag_debian', ];

    [ 'clusterssh'
    , 'dconf-tools'
    , 'pssh'
    , 'smartmontools'
    , 'terminator'
    , 'vinagre'
    , 'xbacklight' ]:
      tag => [ 'tag_admin', 'tag_debian', ];

    [ 'libasound2-plugins'
    , 'mumble'
    , 'pavucontrol'
    , 'pavumeter'
    , 'pulseaudio-esound-compat'
    , 'timidity' ]:
      tag => [ 'tag_audio', 'tag_debian', ];

    [ 'bash'
    , 'bridge-utils'
    , 'gdebi-core'
    , 'grub-pc'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'pm-utils'
    , 'rng-tools'
    , 'udev'
    , 'vlan' ]:
      tag => [ 'tag_basic', 'tag_debian', ];

    # 'indicator-power'			# XXX missing from Debian
    [ 'cinnamon-desktop-environment'
    , 'cinnamon-doc'
    , 'indicator-session'
    , 'lightdm'
    , 'lightdm-gtk-greeter'
    , 'lsb-invalid-mta'
    , 'nautilus-dropbox'
    , 'network-manager-openvpn-gnome'
    , 'notify-osd'
    , 'onboard'
    , 'onboard-data'
    , 'python-appindicator'
    , 'python-gtk2'
    , 'python-notify'
    , 'shared-mime-info'
    , 'xul-ext-mozvoikko' ]:
      tag => [ 'tag_desktop', 'tag_debian', ];

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
    , 'manpages-dev'
    , 'perl-doc'
    , 'pinfo'
    , 'sloccount'
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'tag_devel', 'tag_debian', ];

    # [ 'bcmwl-kernel-source'	# XXX missing from Debian
    [ 'dkms'
    , 'libgl1-mesa-glx'
    # , 'nvidia-legacy-304xx-driver'	# XXX do not install this yet
    # , 'nvidia-settings'		# XXX do not install this yet
    # , 'r8168-dkms'		# XXX missing from Debian
    , 'xserver-xorg-video-all' ]:
      tag => [ 'tag_drivers', 'tag_debian', ];

    [ 'mutt' ]:
      tag => [ 'tag_email', 'tag_debian', ];

    [ 'wine' ]:
      tag => [ 'tag_emulation', 'tag_debian', ];

    [ 'firmware-b43-installer'
    , 'firmware-iwlwifi'
    , 'firmware-linux'
    , 'firmware-linux-free'
    , 'firmware-linux-nonfree'
    , 'firmware-ralink' ]:
      tag => [ 'tag_firmware', 'tag_debian', ];

    [ 'fontconfig'
    , 'ttf-freefont'
    , 'ttf-ubuntu-font-family'
    , 'xfonts-utils' ]:
      tag => [ 'tag_fonts', 'tag_debian', ];

    # needs debconf seeds or such to set license accepted,
    # but package itself is okay
    [ 'ttf-mscorefonts-installer' ]:
      tag => [ 'tag_fonts', 'tag_debian', ];

    [ 'dosbox'
    , 'extremetuxracer'
    , 'freeciv-client-gtk'
    , 'gcompris'
    , 'gcompris-sound-en'
    , 'gcompris-sound-fi'
    , 'gcompris-sound-sv'
    , 'gnubg'
    , 'gnuchess'
    , 'khangman'
    , 'ktouch'
    , 'kwordquiz'
    , 'luola'
    , 'neverball'
    , 'neverputt'
    , 'openttd'
    , 'realtimebattle'
    , 'supertuxkart'
    , 'tuxmath'
    , 'tuxpaint'
    , 'tuxpaint-stamps-default'
    , 'xmoto' ]:
      tag => [ 'tag_games', 'tag_debian', ];

    [ 'consolekit'
    , 'dbus-x11'
    , 'gnome-applets'
    , 'gnome-power-manager'
    , 'gnome-user-guide'
    , 'libgnome2-perl'
    , 'libgnomevfs2-bin'
    , 'libgnomevfs2-extra'
    , 'notification-daemon' ]:
      tag => [ 'tag_gnome', 'tag_debian', ];

    [ 'blender'
    , 'dia'
    , 'dvgrab'
    , 'gimp'
    , 'gimp-data-extras'
    , 'gimp-gap'
    , 'gimp-plugin-registry'
    , 'gimp-ufraw'
    , 'gthumb'
    , 'inkscape'
    , 'kdenlive'
    , 'kino'
    , 'kolourpaint4'
    , 'krita'
    , 'libav-tools'
    , 'libsane'
    , 'libsane-extras'
    # , 'luciole'		# XXX missing from Debian
    , 'mjpegtools'
    , 'mypaint'
    , 'nautilus-image-converter'
    , 'okular'
    , 'openshot'
    # , 'pencil'		# XXX missing from Debian
    # , 'photofilmstrip'	# XXX missing from Debian
    , 'pinta'
    , 'pitivi'
    , 'python-lxml'
    , 'sane-utils'
    , 'xsane' ]:
      tag => [ 'tag_graphics', 'tag_debian', ];

    # XXX some issue on Debian
    # [ 'kdump-tools' ]:
    #   tag => [ 'tag_kernelutils', 'tag_debian', ];

    [ 'irssi'
    , 'irssi-plugin-xmpp'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack' ]:
      tag => [ 'tag_instant_messaging', 'tag_debian', ];

    [ 'laptop-mode-tools' ]:
      tag => [ 'tag_laptop', 'tag_debian', ];

    [ 'banshee'
    # , 'clam-chordata'		# XXX missing from Debian Jessie
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
    , 'libdvdread4'
    # , 'ogmrip'		# XXX missing from Debian
    , 'python-gst0.10'
    , 'vlc'
    , 'vlc-plugin-pulse'
    , 'x264' ]:
      tag => [ 'tag_mediaplayer', 'tag_debian', ];

    [ 'audacity'
    , 'denemo'
    , 'fmit'
    , 'hydrogen'
    , 'lmms'
    , 'musescore'
    , 'musescore-soundfont-gm'
    , 'qsynth'
    , 'rosegarden'
    , 'solfege'
    , 'soundconverter'
    , 'tuxguitar'
    , 'tuxguitar-jsa' ]:
      tag => [ 'tag_music_making', 'tag_debian', ];

    [ 'amtterm'
    , 'ipsec-tools'
    , 'racoon' ]:
    # , 'wsmancli' ]:	# XXX missing from Debian
      tag => [ 'tag_network', 'tag_debian', ];

    [ 'calibre'
    , 'icedove'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'scribus'
    , 'scribus-doc'
    , 'tellico'
    , 'vym' ]:
      tag => [ 'tag_office', 'tag_debian', ];

    [ 'eject'
    , 'sound-juicer' ]:
      tag => [ 'tag_optical_media', 'tag_debian', ];

    # XXX missing from Debian
    # [ 'gtklp' ]:
    #   tag => [ 'tag_printing', 'tag_debian', ];

    [ 'arduino'
    , 'arduino-mk'
    , 'avr-libc'
    # 'basic256'		# XXX missing from Debian Jessie
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
    , 'kturtle'
    , 'lokalize'
    , 'pyqt4-dev-tools'
    , 'python-doc'
    , 'python-jsonpickle' # a dependency for
                          # http://meetedison.com/robot-programming-software/
    , 'python-pygame'
    , 'pythontracer'
    , 'qt4-designer'
    , 'qt4-doc'
    , 'racket'
    , 'scratch'
    , 'spe' ]:
      tag => [ 'tag_programming', 'tag_debian', ];

    # 'gftp-gtk'	# XXX missing from Debian
    [ 'libmotif4'	# required by icaclient
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'wget'
    , 'xtightvncviewer']:
      tag => [ 'tag_remote_access', 'tag_debian', ];

    [ 'avogadro'
    , 'celestia'
    , 'celestia-common-nonfree'
    , 'celestia-gnome'
    # , 'drgeo'		# XXX missing from Debian
    # , 'ghemical'	# XXX missing from Debian
    , 'gnucap'
    , 'gnuplot'
    , 'gnuplot-x11'
    , 'kalzium'
    , 'kbruch'
    , 'kgeography'
    , 'kmplot'
    , 'kstars'
    , 'mandelbulber'
    , 'marble-qt'
    , 'qgis'
    , 'stellarium'
    , 'texlive-fonts-extra'
    , 'texlive-fonts-recommended'
    , 'texlive-latex-extra'
    , 'texlive-latex-recommended'
    , 'wxmaxima' ]:
      tag => [ 'tag_science', 'tag_debian', ];

    # 'breathe-icon-theme'		# XXX missing from Debian
    [ 'gnome-icon-theme'
    , 'gnome-themes-extras'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    # , 'human-theme'			# XXX missing from Debian
    # , 'light-themes'			# XXX missing from Debian
    , 'openclipart'
    , 'oxygen-icon-theme'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'tag_themes', 'tag_debian', ];

    [ 'debian-edu-artwork'
    , 'debian-edu-artwork-joy'
    , 'debian-edu-artwork-lines'
    , 'debian-edu-artwork-spacefun' ]:
      tag => [ 'tag_backgroundimages', 'tag_themes', 'tag_debian', 'tag_jessie', ];

    # the dependencies (and recommends) of ubuntu-gnome-desktop package
    # without a few packages that we do not want
    [ 'acpi-support'
    , 'alsa-base'
    , 'alsa-utils'
    , 'anacron'
    , 'at-spi2-core'
    , 'avahi-autoipd'
    , 'avahi-daemon'
    , 'baobab'
    , 'bc'
    , 'bluez'
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
    , 'gnome-clocks'
    , 'gnome-contacts'
    , 'gnome-control-center'
    , 'gnome-disk-utility'
    # , 'gnome-documents'	# forces tracker to be installed
				# (tracker is purged elsewhere)
    , 'gnome-icon-theme-extras'
    , 'gnome-icon-theme-symbolic'
    , 'gnome-keyring'
    , 'gnome-menus'
    , 'gnome-online-accounts'
    , 'gnome-screenshot'
    , 'gnome-session'
    , 'gnome-session-canberra'
    , 'gnome-settings-daemon'
    , 'gnome-shell'
    , 'gnome-shell-extensions'
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
    , 'libxp6'
    , 'make'
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
    , 'plymouth'
    , 'plymouth-themes'
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
    , 'rtmpdump'
    , 'rxvt-unicode'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    # , 'software-properties-gtk'		# (purged elsewhere)
    , 'speech-dispatcher'
    , 'ssh-askpass-gnome'
    , 'telepathy-idle'
    , 'totem'
    # , 'tracker'				# (purged elsewhere)
    , 'transmission-gtk'
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
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'youtube-dl'
    , 'zenity'
    , 'zip' ]:
      tag => [ 'tag_ubuntu-gnome-desktop', 'tag_debian', ];

    [ 'bindfs'
    , 'desktop-file-utils'
    , 'duplicity'
    , 'exfat-fuse'
    , 'exfat-utils'
    , 'fuse'
    , 'gconf-editor'
    # , 'ginn'			# XXX needs packaging for Debian ?
    # , 'touchegg'		# XXX needs packaging for Debian ?
    , 'unace'
    , 'unionfs-fuse' # Ekapeli might need this.
    , 'unrar' ]:
      tag => [ 'tag_utils', 'tag_debian', ];

    [ 'qemu-kvm' ]:
      tag => [ 'tag_virtualization', 'tag_debian', ];

    [ 'bluefish'
    , 'browser-plugin-vlc'
    , 'chromium'
    , 'epiphany-browser'
    , 'flashplugin-nonfree'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-7-jdk'
    , 'openjdk-7-jre'
    , 'openjdk-8-jdk'
    , 'openjdk-8-jre'
    , 'php5-cli'
    , 'php5-sqlite'
    , 'sqlite3' ]:
      tag => [ 'tag_web', 'tag_debian', ];
  }

  #
  # packages from the (Opinsys) puavo repository
  #

  @package {
    'nodejs-bundle':
      tag => [ 'tag_devel', 'tag_puavo', ];

    'autopoweroff':
      tag => [ 'tag_misc', 'tag_puavo', ];

    # [ 'fluent-plugin-puavo'   # XXX not yet packaged for Debian
    # , 'puavo-load-reporter'   # XXX not yet packaged for Debian
    # , 'simplescreenrecorder'          # XXX not yet packaged for Debian
    # , 'xexit' ]:                      # XXX not yet packaged for Debian

    'libssl-dev':
      ensure => '1.0.1e-2+deb7u20',
      require => Package['libssl1.0.0'];

    'libssl1.0.0':
      ensure => '1.0.1e-2+deb7u20',
      require => Package['openssl'];

    'openssl':
      ensure  => '1.0.1e-2+deb7u20';

    'vtun':
      ensure => '3.0.2-5+trusty.amd64+master.531cf0dbc32b3c20a22e783612e968055ffb1d1e';

    # XXX not yet packaged for Debian
    # [ 'dymo-cups-drivers' ]:
    #   tag => [ 'tag_printing', 'tag_puavo', ];

    # XXX not yet packaged for Debian
    # [ 'bluegriffon'
    # , 'enchanting'
    # , 'pycharm'
    # , 'snap4arduino' ]:
    #   tag => [ 'tag_programming', 'tag_puavo', ];

    'x2goclient':
    # 'x2goserver' # XXX not yet packaged for Debian
      tag => [ 'tag_remote_access', 'tag_puavo', ];

    [ 'faenza-icon-theme' ]:
      tag => [ 'tag_themes', 'tag_puavo', ];
  }

  $bcmwl_dkms_module  = 'bcmwl/6.30.223.248+bdcom'
  $nvidia_dkms_module = 'nvidia-304/304.128'
  $r8168_dkms_module  = 'r8168/8.040.00'
  $all_dkms_modules   = []
			# XXX $nvidia_dkms_module # XXX needs fixing
			# XXX $bcmwl_dkms_module  # XXX missing from Debian
			# XXX $r8168_dkms_module  # XXX missing from Debian

  case $lsbdistcodename {
    'jessie': {
      packages::kernels::kernel_package {
        '3.16.0-4-amd64':
          dkms_modules => $all_dkms_modules;
        # XXX disabled due to linux-base 4.3 dependency
        # '4.6.0-0.bpo.1-amd64':
        #   dkms_modules => $all_dkms_modules;
      }
    }
    'stretch': {
      packages::kernels::kernel_package {
        '4.6.0-1-amd64':
          dkms_modules => $all_dkms_modules;
      }
    }
  }

  #
  # packages from the canonical/ubuntu partner repository
  #

  # XXX missing from Debian
  # @package {
  #   [ 'skype' ]:
  #     tag => [ 'tag_instant_messaging', 'tag_partner', 'tag_extra', 'tag_restricted' ];
  #
  #   XXX missing from Debian
  #   [ 'vmware-view-client' ]:
  #     tag => [ 'tag_remote_access', 'tag_partner', 'tag_restricted' ];
  # }

  # Packages which are not restricted per se, but which are required by
  # restricted packages. These need to be installed and distributed in
  # the image to minimize the effort of installing restricted packages
  # "during runtime".
  @package {
    [ 'libnspr4-0d' # spotify
    , 'lsb-core' ]: # google-earth
      tag => [ 'tag_debian', 'tag_required-by-restricted' ];
  }

  # i386-support packages for the amd64-architecture.
  # There are explicit or found-by-trial -dependencies of the following
  # software packages: adobereader-enu, skype, smartboard.
  if $architecture == 'amd64' {
    @package {
      [ 'debianutils:i386'
      , 'init-system-helpers:i386'
      , 'libasound2:i386'
      , 'libasound2-plugins:i386'
      , 'libbluetooth3:i386'
      , 'libc6:i386'
      , 'libcap-ng0:i386'
      , 'libcurl3:i386'
      , 'libfontconfig1:i386'
      , 'libfreetype6:i386'
      , 'libgcc1:i386'
      , 'libgl1-mesa-glx:i386'
      , 'libglib2.0-0:i386'
      , 'libgtk2.0-0:i386'
      , 'libice6:i386'
      , 'libltdl7:i386'
      , 'libnspr4-0d:i386'
      , 'libpulse0:i386'
      , 'libqt4-dbus:i386'
      , 'libqt4-network:i386'
      , 'libqt4-xml:i386'
      , 'libqtcore4:i386'
      , 'libqtgui4:i386'
      , 'libqtwebkit4:i386'
      , 'libselinux1:i386'
      , 'libsm6:i386'
      , 'libssl1.0.0:i386'
      , 'libstdc++6:i386'
      , 'libudev0:i386'
      , 'libudev1:i386'
      , 'libuuid1:i386'
      , 'libx11-6:i386'
      , 'libxext6:i386'
      , 'libxinerama1:i386'
      , 'libxkbfile1:i386'
      , 'libxml2:i386'
      , 'libxrender1:i386'
      , 'libxslt1.1:i386'
      , 'libxss1:i386'
      , 'libxtst6:i386'
      , 'libxv1:i386'
      , 'lsb-base:i386'
      , 'zlib1g:i386' ]:
        ensure => present,
        tag    => [ 'tag_debian', 'tag_i386' ];
    }
  }
}
