class packages {
  require ::apt::multiarch
  # require ::apt::virtualbox   # XXX Bullseye
  include ::packages::backports
  include ::packages::compat_32bit
  include ::packages::pinned
  include ::packages::purged

  # install packages by default
  Package { ensure => present, }

  #
  # Puavo OS packages
  #

  @package {
    [ 'puavo-ltsp-bootserver', 'puavo-rest', ]:
      ensure => present,
      tag    => [ 'tag_puavo_bootserver' ];
  }

  @package {
    [ 'puavo-autopilot'
    , 'puavo-autopoweroff'
    , 'puavo-bigtouch-shutdown'
    , 'puavo-blackboard'
    , 'puavo-client'
    , 'puavo-conf'
    , 'puavo-core'
    , 'puavo-desktop-applet'
    , 'puavo-devscripts'
    , 'puavo-ers'
    , 'puavo-hw-tools'
    , 'puavo-laptop-setup'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-pam'
    , 'puavo-pkg'
    , 'puavo-sharedir-client'
    , 'puavo-usb-factory'
    , 'puavo-user-registration'
    , 'puavo-vpn-client'
    , 'puavo-webwindow'
    # , 'puavo-wlanap'          # XXX missing from Bullseye
    # , 'puavo-wlanmapper'      # XXX missing from Bullseye
    , 'puavo-wlangw'
    , 'puavomenu'
    , 'ruby-puavowlan'
    , 'webkiosk-language-selector' ]:
      ensure => present,
      tag    => [ 'tag_puavo' ];
  }

  #
  # packages from the Debian repositories
  #

  @package {
    [ 'bind9'
    , 'bind9utils'
    , 'cifs-utils'
    , 'dnsmasq'
    # , 'incron'                # XXX missing from Bullseye
    , 'gpm'
    , 'isc-dhcp-server'
    , 'krb5-kdc'
    , 'libudev1'
    , 'logrotate'
    , 'mdadm'
    , 'monitoring-plugins'
    , 'munin'
    , 'munin-node'
    , 'nagios-nrpe-server'
    , 'nagios-plugins-contrib'
    , 'nginx'
    , 'openbsd-inetd'
    , 'policykit-1'
    , 'python3-numpy'
    , 'python3-redis'
    , 'pxelinux'
    , 'redis-server'
    , 'ruby-ipaddress'
    , 'samba'
    , 'shorewall'
    , 'slapd'
    , 'syslinux-common'
    , 'syslinux-efi'
    , 'winbind' ]:
      tag => [ 'tag_basic', 'tag_debian_bootserver', ];
  }

  @package {
    [ 'acpitool'
    , 'arandr'
    , 'atop'
    , 'avahi-utils'
    , 'clusterssh'
    , 'console-setup'
    , 'dconf-cli'
    , 'elinks'
    , 'ethtool'
    , 'expect'
    , 'fping'
    , 'gawk'
    , 'git'
    , 'htop'
    , 'iftop'
    , 'inetutils-traceroute'
    , 'initramfs-tools'
    , 'initramfs-tools-core'
    , 'inotify-tools'
    , 'iotop'
    , 'iperf'
    , 'libstdc++5'
    , 'linssid'
    , 'lm-sensors'
    , 'lshw'
    , 'lsof'
    , 'ltrace'
    , 'lynx'
    , 'm4'
    , 'mesa-utils'
    , 'mlocate'
    , 'moreutils'
    , 'nmap'
    , 'powertop'
    , 'procps'
    , 'pssh'
    , 'pv'
    , 'pwgen'
    , 'pwman3'
    , 'read-edid'
    , 'rsyslog'
    , 'screen'
    , 'secure-delete'
    , 'setserial'
    , 'smartmontools'
    , 'sshfs'
    , 'strace'
    , 'sudo'
    , 'sysbench'
    , 'sysfsutils'
    , 'sysstat'
    , 'tftp'
    , 'telnet'
    , 'terminator'
    , 'tmux'
    , 'tshark'
    , 'ulogd2'
    , 'vinagre'
    , 'vrms'
    , 'w3m'
    , 'wakeonlan'
    , 'wavemon'
    , 'whois'
    # , 'wsmancli'              # XXX missing from Bullseye
    , 'x11vnc'
    , 'xbacklight'
    , 'xinput-calibrator' ]:
      tag => [ 'tag_admin', 'tag_debian_desktop', ];

    [ 'espeak-ng'
    , 'libasound2-plugins'
    , 'linphone'
    , 'mumble'
    , 'pavucontrol'
    , 'pavumeter'
    , 'qstopmotion'
    , 'simplescreenrecorder'
    , 'timidity' ]:
      tag => [ 'tag_audio', 'tag_debian_desktop', ];

    [ 'bash'
    , 'bash-completion'
    , 'bridge-utils'
    , 'efibootmgr'
    , 'gdebi-core'
    , 'grub-efi-amd64-bin'
    , 'grub-efi-ia32-bin'
    , 'grub-pc'
    , 'grub-pc-bin'
    , 'ksh'
    , 'libc++1'        #needed by discord
    , 'libpam-ccreds'
    , 'libpam-krb5'
    , 'libpam-ldapd'
    , 'libpam-modules'
    , 'libpam-runtime'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'pm-utils'
    , 'rng-tools'
    , 'systemd'
    , 'udev'
    , 'vlan' ]:
      tag => [ 'tag_basic', 'tag_debian_desktop', ];

    [ 'debootstrap'
    , 'squashfs-tools'
    , 'systemd-container' ]:
      tag => [ 'tag_builder', 'tag_debian_desktop', ];

    [ 'gdm3'
    , 'i3'
    , 'nautilus-nextcloud'
    , 'network-manager-openvpn-gnome'
    , 'network-manager-vpnc-gnome'
    , 'nextcloud-desktop'
    , 'nextcloud-desktop-cmd'
    , 'notify-osd'
    , 'onboard'
    , 'onboard-data'
    # , 'python-gtk2'           # XXX missing from Bullseye
    , 'python3-notify2'
    , 'shared-mime-info'
    , 'suckless-tools'
    , 'unclutter'
    , 'xmobar'
    , 'xmonad' ]:
      tag => [ 'tag_desktop', 'tag_debian_desktop', ];

    [ 'acct'
    , 'ack'
    , 'build-essential'
    , 'bvi'
    , 'cdbs'
    , 'debconf-doc'
    , 'devscripts'
    , 'dh-make'
    , 'dpkg-dev'
    , 'dput'
    , 'fakeroot'
    , 'gcc'
    , 'gdb'
    , 'gettext'
    , 'glade'
    , 'gnupg'
    , 'manpages-dev'
    , 'perl-doc'
    , 'pinfo'
    , 'shellcheck'
    , 'sloccount'
    , 'tcl8.6-doc'
    , 'tcl-thread'
    , 'tk8.6-doc'
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'tag_devel', 'tag_debian_desktop', ];

    [ 'dkms'
    , 'glx-alternative-mesa'
    , 'libgl1-mesa-glx'
    , 'nvidia-settings'
    , 'update-glx'
    , 'xserver-xorg-input-all'
    , 'xserver-xorg-input-evdev'
    , 'xserver-xorg-video-all' ]:
      tag => [ 'tag_drivers', 'tag_debian_desktop', ];

    [ 'mutt' ]:
      tag => [ 'tag_email', 'tag_debian_desktop', ];

    # XXX virtualbox - Bullseye
    # [ 'virtualbox-6.1'
    [ 'wine'
    , 'wine32'
    # , 'wine-development'      # XXX missing from Bullseye
    # , 'wine32-development'    # XXX missing from Bullseye
    # , 'wine64-development'    # XXX missing from Bullseye
    , 'winetricks' ]:
      tag => [ 'tag_emulation', 'tag_debian_desktop', ];

    'firmware-linux-free':
      tag => [ 'tag_firmware', 'tag_debian_desktop', ];

    [ 'fontconfig'
    , 'fonts-ubuntu'
    , 'gnome-font-viewer'
    , 'xfonts-terminus'
    , 'xfonts-utils' ]:
      tag => [ 'tag_fonts', 'tag_debian_desktop', ];

    [ 'aisleriot'
    , 'dosbox'
    , 'freeciv-client-gtk'
    , 'gcompris-qt'
    , 'gnome-games'
    , 'gnubg'
    , 'gnuchess'
    , 'khangman'
    , 'ktouch'
    , 'kwordquiz'
    , 'laby'
    , 'luola'
    , 'minetest'
    , 'neverball'
    , 'neverputt'
    , 'openttd'
    , 'qml-module-qtquick-dialogs'	        # needed by teamviewer
    , 'qml-module-qtquick-privatewidgets'	# needed by teamviewer
    , 'qml-module-qtmultimedia'	                # required by khangman
    , 'tuxmath'
    , 'tuxpaint'
    , 'tuxpaint-stamps-default'
    , 'xmoto' ]:
      tag => [ 'tag_games', 'tag_debian_desktop', ];

    [ 'dbus-x11'
    , 'gnome-applets'
    , 'gnome-power-manager'
    , 'gnome-user-guide'
    , 'notification-daemon' ]:
      tag => [ 'tag_gnome', 'tag_debian_desktop', ];

    [ 'blender'
    , 'breeze-icon-theme'	# wanted (not required) by kdenlive
    , 'dia'
    , 'dvgrab'
    , 'feh'
    , 'freecad'
    , 'gimp'
    , 'gimp-data-extras'
    , 'gimp-gap'
    , 'gimp-plugin-registry'
    # , 'gimp-ufraw'            # XXX missing from Bullseye
    , 'godot3'
    , 'gthumb'
    , 'inkscape'
    , 'kdenlive'
    # , 'kino'                  # XXX missing from Bullseye
    , 'kolourpaint4'
    , 'krita'
    , 'krita-l10n'
    , 'libsane'
    , 'mjpegtools'
    , 'mypaint'
    , 'nautilus-image-converter'
    , 'obs-studio'
    , 'okular'
    , 'openscad'
    , 'openshot-qt'
    , 'pencil2d'
    # , 'pinta'                 # XXX missing from Bullseye
    , 'pitivi'
    , 'python3-lxml'
    , 'sane-utils'
    , 'xsane' ]:
      tag => [ 'tag_graphics', 'tag_debian_desktop', ];

    # XXX some issue on Debian
    # [ 'kdump-tools' ]:
    #   tag => [ 'tag_kernelutils', 'tag_debian_desktop', ];

    [ 'irssi'
    , 'irssi-plugin-xmpp'
    , 'pidgin'
    , 'pidgin-plugin-pack'
    , 'telegram-desktop' ]:
      tag => [ 'tag_instant_messaging', 'tag_debian_desktop', ];

    # XXX enable if issues are fixed
    # [ 'laptop-mode-tools' ]:
    #   tag => [ 'tag_laptop', 'tag_debian_desktop', ];

    [ 'goobox'
    , 'gstreamer1.0-clutter-3.0'
    , 'gstreamer1.0-libav'
    , 'gstreamer1.0-plugins-bad'
    , 'gstreamer1.0-plugins-base'
    , 'gstreamer1.0-plugins-good'
    , 'gstreamer1.0-plugins-ugly'
    , 'gstreamer1.0-tools'
    , 'kaffeine'
    , 'libdvd-pkg'
    , 'libdvdread8'
    , 'ogmrip'
    , 'recordmydesktop'
    , 'regionset'
    , 'smplayer'
    , 'vlc'
    , 'winff'
    , 'x264' ]:
      tag => [ 'tag_mediaplayer', 'tag_debian_desktop', ];

    [ 'audacity'
    , 'denemo'
    , 'fmit'
    , 'hydrogen'
    , 'lmms'
    , 'musescore3'
    , 'qsynth'
    , 'rosegarden'
    , 'solfege'
    , 'soundconverter'
    , 'tuxguitar'
    , 'tuxguitar-jsa' ]:
      tag => [ 'tag_music_making', 'tag_debian_desktop', ];

    [ 'amtterm'
    , 'hostapd'
    , 'vtun' ]:
      tag => [ 'tag_network', 'tag_debian_desktop', ];

    [ 'calibre'
    , 'freeplane'
    , 'gummi'
    , 'impressive'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'scribus'
    , 'sent'
    , 'tellico'
    , 'texmaker'
    , 'thunderbird'
    , 'vym' ]:
      tag => [ 'tag_office', 'tag_debian_desktop', ];

    [ 'eject'
    , 'devede'
    , 'sound-juicer' ]:
      tag => [ 'tag_optical_media', 'tag_debian_desktop', ];

    [ 'cups-browsed'
    , 'cups-daemon'
    , 'cups-pk-helper'
    # , 'google-cloud-print-connector'  # XXX missing from Bullseye
    , 'gtklp' ]:
      tag => [ 'tag_printing', 'tag_debian_desktop', ];

    [ 'adb'
    , 'aseba'
    , 'avr-libc'
    , 'emacs'
    , 'eric'
    , 'eric-api-files'
    , 'fastboot'
    , 'fritzing'
    , 'gcc-avr'
    , 'geany'
    , 'idle'
    , 'idle-python2.7'
    , 'idle-python3.9'
    , 'kturtle'
    , 'lazarus'
    , 'lokalize'
    , 'meld'
    , 'pylint'
    # , 'pyqt4-dev-tools'       # XXX missing from Bullseye
    , 'python3-doc'
    , 'python3-jsonpickle' # a dependency for
                           # http://meetedison.com/robot-programming-software/
    , 'python3-pip'
    , 'python3-pygame'
    # , 'pythontracer'  # XXX missing from Bullseye
    # , 'qt4-designer'  # XXX missing from Bullseye
    # , 'qt4-doc'       # XXX missing from Bullseye
    , 'racket'
    # , 'renpy'         # XXX missing from Bullseye
    , 'sbcl'
    , 'scite'
    , 'scratch'
    , 'sonic-pi' ]:
    # , 'spe' ]:        # XXX missing from Bullseye
      tag => [ 'tag_programming', 'tag_debian_desktop', ];

    [ 'epoptes'
    , 'epoptes-client'
    , 'filezilla'
    , 'gftp'
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'veyon-configurator'
    , 'veyon-master'
    , 'veyon-plugins'
    , 'veyon-service'
    , 'wget'
    , 'xtightvncviewer' ]:
      tag => [ 'tag_remote_access', 'tag_debian_desktop', ];

    [ 'avogadro'
    , 'gnucap'
    , 'gnuplot'
    , 'gnuplot-x11'
    , 'kalzium'
    , 'kbruch'
    , 'kgeography'
    , 'kmplot'
    , 'kstars'
    , 'mandelbulber2'
    , 'marble-qt'
    , 'pspp'
    , 'qgis'
    , 'stellarium'
    , 'step'
    , 'texlive-fonts-recommended'
    , 'texlive-latex-extra'
    , 'texlive-latex-recommended'
    , 'wxmaxima' ]:
      tag => [ 'tag_science', 'tag_debian_desktop', ];

    [ 'gnome-icon-theme'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    , 'openclipart'
    , 'oxygen-icon-theme'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'tag_themes', 'tag_debian_desktop', ];

    # desktop-packages relating to gnome and other, some of these
    # maybe belong to other categories or may be removed
    [ 'acpi-support'
    , 'adwaita-icon-theme'
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
    , 'ca-certificates'
    , 'cheese'
    , 'cups'
    , 'cups-bsd'
    , 'cups-client'
    , 'cups-filters'
    , 'dconf-editor'
    , 'empathy'
    , 'eog'
    , 'evince'
    , 'evolution'
    , 'file-roller'
    , 'fonts-cantarell'
    , 'fonts-dejavu-core'
    , 'fonts-freefont-ttf'
    , 'foomatic-db-compressed-ppds'
    , 'gcr'
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
    , 'gnome-keyring'
    , 'gnome-menus'
    , 'gnome-online-accounts'
    , 'gnome-orca'
    , 'gnome-screenshot'
    , 'gnome-session'
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
    , 'gstreamer1.0-alsa'
    , 'gstreamer1.0-pulseaudio'
    , 'gucharmap'
    , 'gvfs-bin'
    , 'gvfs-fuse'
    , 'hplip'
    , 'ibus'
    , 'ibus-anthy'
    , 'ibus-gtk3'
    , 'ibus-pinyin'
    , 'ibus-table'
    , 'inputattach'
    , 'itstool'
    , 'kcalc'
    , 'laptop-detect'
    , 'libatk-adaptor'
    , 'libgail-common'
    , 'libnotify-bin'
    , 'libnss-extrausers'
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
    # , 'libreoffice-pdfimport'                 # XXX missing from Bullseye
    # , 'libreoffice-style-tango'               # XXX missing from Bullseye
    , 'libreoffice-writer'
    , 'libsasl2-modules'
    , 'libxcb-xtest0' #dependency for Zoom
    , 'make'
    , 'memtest86+'
    , 'mousetweaks'
    , 'mutter'
    , 'nautilus'
    , 'nautilus-sendto'
    , 'network-manager'
    , 'network-manager-l2tp'                    # needed by citrix
    , 'network-manager-l2tp-gnome'              # needed by citrix
    , 'network-manager-pptp'
    , 'network-manager-pptp-gnome'
    , 'nodm'                                    # for infotv
    , 'openprinting-ppds'
    , 'pcmciautils'
    , 'plymouth'
    , 'plymouth-themes'
    , 'printer-driver-all'
    , 'printer-driver-c2esp'
    , 'printer-driver-cups-pdf'
    , 'printer-driver-foo2zjs'
    , 'printer-driver-gutenprint'
    , 'printer-driver-min12xxw'
    , 'printer-driver-pnm2ppa'
    , 'printer-driver-ptouch'
    , 'printer-driver-pxljr'
    , 'printer-driver-sag-gdi'
    , 'printer-driver-splix'
    , 'pulseaudio'
    , 'pulseaudio-module-bluetooth'
    , 'rfkill'
    , 'rtmpdump'
    , 'rxvt-unicode'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    , 'speech-dispatcher'
    , 'speedcrunch'
    , 'ssh-askpass-gnome'
    , 'telepathy-idle'
    , 'totem'
    , 'transmission-gtk'
    , 'unzip'
    , 'vino'
    , 'wireless-tools'
    , 'wpasupplicant'
    , 'xdg-user-dirs'
    , 'xdg-user-dirs-gtk'
    , 'xdg-utils'
    , 'xkb-data'
    , 'xorg'
    , 'xterm'
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'youtube-dl'
    , 'zenity'
    , 'zip' ]:
      tag => [ 'tag_gnome_desktop', 'tag_debian_desktop', ];

    # some dependencies from puavopkg packages
    [ # XXX buster 'libjavascriptcoregtk-1.0-0'        # citrix client
      'libopencsg1'                       # openscad-nightly
    , 'libqt5quickcontrols2-5'            # mafynetti
    , 'libqt5quicktemplates2-5'           # mafynetti
    , 'libqt5webenginewidgets5'           # promethean
    # XXX buster , 'libwebkitgtk-1.0-0'   # citrix client
    # XXX bullseye , 'libqwt5-qt4'        # aseba
    , 'qml-module-qtquick-controls2'      # mafynetti
    , 'qml-module-qtquick-templates2'     # mafynetti
    ]:
      tag => [ 'tag_puavopkg', 'tag_debian_desktop', ];

    [ 'anki'
    , 'bindfs'
    , 'blueman'
    , 'desktop-file-utils'
    , 'detox'
    , 'devilspie2'
    , 'duplicity'
    , 'exfat-fuse'
    , 'exfat-utils'
    , 'fuse3'
    # , 'gconf-editor'    # XXX missing from Bullseye
    # , 'kamerka'         # XXX missing from Bullseye
    , 'mc'
    , 'mousepad'
    , 'p7zip-full'
    , 'pass'
    , 'password-gorilla'
    , 'system-config-printer'
    , 'tlp'
    , 'unace'
    , 'unionfs-fuse'    # Ekapeli might need this.
    , 'wmctrl'
    , 'xinput' ]:
      tag => [ 'tag_utils', 'tag_debian_desktop', ];

    [ 'qemu-system-x86'
    , 'virt-manager' ]:
      tag => [ 'tag_virtualization', 'tag_debian_desktop', ];

    [ 'bluefish'
    , 'chromium'
    , 'chromium-l10n'
    , 'epiphany-browser'
    , 'icedtea-netx'
    , 'liferea'
    , 'openjdk-11-jdk'
    , 'openjdk-11-jre'
    , 'php-cli'
    , 'php-sqlite3'
    , 'sqlite3' ]:
      tag => [ 'tag_web', 'tag_debian_desktop', ];
  }

  #
  # packages from the (Opinsys) puavo repository
  #

  @package {
    [ 'arc-theme'
    , 'deepin-icon-theme'
    , 'faenza-icon-theme'
    , 'obsidian-icon-theme' ]:
      tag => [ 'tag_themes', 'tag_puavo', ];

   'openboard':
     tag => [ 'tag_whiteboard', 'tag_puavo', ];
  }

  $broadcom_sta_dkms_module = 'broadcom-sta/6.30.223.271'
  $nvidia_dkms_340_module   = 'nvidia-legacy-340xx/340.108'
  $nvidia_dkms_390_module   = 'nvidia-legacy-390xx/390.143'
  $nvidia_dkms_410_module   = 'nvidia-current/418.197.02'
  $r8168_module             = 'r8168/8.046.00'

  $all_dkms_modules = [ $broadcom_sta_dkms_module
                      , $nvidia_dkms_340_module
                      , $nvidia_dkms_390_module
                      , $nvidia_dkms_410_module
		      , $r8168_module ]

  packages::kernels::kernel_package {
    '5.10.0-6-amd64':
      # XXX fix dkms_modules for Bullseye
      dkms_modules => [],
      package_name => 'linux-image-5.10.0-6-amd64';
  }

  # Packages which are not restricted per se, but which are required by
  # restricted packages. These need to be installed and distributed in
  # the image to minimize the effort of installing restricted packages
  # "during runtime".
# XXX buster
# @package {
#   [ 'libnspr4-0d'    # spotify
#   , 'libssl1.0.0'    # spotify
#   , 'lsb-core' ]:    # google-earth
#     tag => [ 'tag_debian_desktop', 'tag_required-by-restricted' ];
# }

  # various contrib/non-free stuff, firmwares and such
  @package {
    'nautilus-dropbox':
      tag => [ 'tag_debian_desktop', 'tag_debian_desktop_nonfree', ];

    # XXX do not try to install nvidia yet on Bullseye
    # , 'libgl1-nvidia-glx'
    # , 'libgl1-nvidia-legacy-340xx-glx'
    # , 'libgl1-nvidia-legacy-390xx-glx'
    # , 'nvidia-kernel-dkms'
    # , 'nvidia-legacy-340xx-kernel-dkms'
    # , 'nvidia-legacy-390xx-kernel-dkms'
    # , 'xserver-xorg-video-nvidia'
    # , 'xserver-xorg-video-nvidia-legacy-340xx'
    # , 'xserver-xorg-video-nvidia-legacy-390xx' ]:
    [ 'broadcom-sta-dkms'
    , 'r8168-dkms' ]:
      tag => [ 'tag_drivers', 'tag_debian_desktop_nonfree', ];

    [ 'amd64-microcode'
    , 'b43-fwcutter'
    , 'firmware-amd-graphics'
    , 'firmware-atheros'
    , 'firmware-b43-installer'
    , 'firmware-b43legacy-installer'
    , 'firmware-bnx2'
    , 'firmware-bnx2x'
    , 'firmware-brcm80211'
    , 'firmware-cavium'
    , 'firmware-intel-sound'
    , 'firmware-intelwimax'
    , 'firmware-ipw2x00'
    , 'firmware-ivtv'
    , 'firmware-iwlwifi'
    , 'firmware-libertas'
    , 'firmware-linux'
    , 'firmware-linux-nonfree'
    , 'firmware-misc-nonfree'
    , 'firmware-myricom'
    , 'firmware-netxen'
    , 'firmware-qlogic'
    , 'firmware-realtek'
    , 'firmware-samsung'
    , 'firmware-siano'
    , 'firmware-ti-connectivity'
    , 'firmware-zd1211'
    , 'intel-microcode'
    , 'iucode-tool' ]:
      ensure => present,
      tag    => [ 'tag_firmware', 'tag_debian_nonfree', ];

    'steam':
      tag => [ 'tag_games', 'tag_debian_desktop_nonfree', ];

    'scribus-doc':
      tag => [ 'tag_office', 'tag_debian_desktop_nonfree', ];

    'unrar':
      tag => [ 'tag_utils', 'tag_debian_nonfree', ];
  }
}
