class packages {
  require ::apt::multiarch
  include ::packages::backports
  include ::packages::compat_32bit
  include ::packages::fasttrack
  include ::packages::pinned
  include ::packages::purged

  # install packages by default
  Package { ensure => present, }

  #
  # Puavo OS packages
  #

  @package {
    [ 'hooktftp'
    , 'puavo-ltsp-bootserver'
    , 'puavo-rest' ]:
      ensure => present,
      tag    => [ 'tag_puavo_bootserver' ];
  }

  @package {
    [ 'puavo-autopilot'
    , 'puavo-autopoweroff'
    , 'puavo-blackboard'
    , 'puavo-client'
    , 'puavo-conf'
    , 'puavo-core'
    , 'puavo-desktop'
    , 'puavo-desktop-applet'
    , 'puavo-devscripts'
    , 'puavo-ers'
    , 'puavo-exammode'
    , 'puavo-laptop-setup'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-pam'
    , 'puavo-pkg'
    , 'puavo-sharedir-client'
    , 'puavo-sharedir-manager'
    , 'puavo-usb-factory'
    , 'puavo-user-registration'
    , 'puavo-veyon-applet'
    , 'puavo-vpn-client'
    , 'puavo-webkiosk'
    , 'puavo-webwindow'
    , 'puavomenu' ]:
      ensure => present,
      tag    => [ 'tag_puavo' ];
  }

  #
  # packages from the Debian repositories
  #

  @package {
    [ 'bind9'
    , 'bind9-utils'
    , 'cifs-utils'
    , 'cryptsetup'
    , 'cryptsetup-initramfs'
    , 'dbus'
    , 'dnsmasq'
    , 'docker-compose'
    , 'docker.io'
    , 'dracut'
    , 'freeradius'
    , 'freeradius-krb5'
    , 'freeradius-ldap'
    , 'gpm'
    , 'incron'
    , 'ipcalc'
    , 'isc-dhcp-server'
    , 'kbd'
    , 'krb5-admin-server'
    , 'krb5-kdc'
    , 'libudev1'
    , 'logrotate'
    , 'mdadm'
    , 'monitoring-plugins'
    , 'monitoring-plugins-contrib'
    , 'munin'
    , 'munin-node'
    , 'nagios-nrpe-server'
    , 'nginx'
    , 'openbsd-inetd'
    # , 'policykit-1'                   # XXX missing from Trixie
    # , 'polkitd-pkla'                  # XXX missing from Trixie
    , 'python3-numpy'
    , 'python3-redis'
    , 'pxelinux'
    , 'redis-server'
    , 'ruby-ipaddress'
    , 'ruby-net-ldap'
    , 'samba'
    , 'shorewall'
    , 'slapd'
    , 'syslinux-common'
    , 'syslinux-efi'
    , 'tpm2-tools'
    , 'winbind' ]:
      tag => [ 'tag_basic', 'tag_debian_bootserver', ];
  }

  @package {
    [ 'acpitool'
    , 'arandr'
    , 'atop'
    , 'avahi-utils'
    , 'chntpw'
    , 'clusterssh'
    , 'console-setup'
    , 'dconf-cli'
    , 'elinks'
    , 'ethtool'
    , 'expect'
    , 'f2fs-tools'
    , 'fping'
    , 'fwupd'
    , 'gawk'
    , 'git'
    , 'htop'
    , 'iftop'
    , 'inetutils-traceroute'
    , 'inotify-tools'
    , 'iotop'
    , 'iperf'
    , 'jc'
    , 'jq'
    , 'linssid'
    , 'lm-sensors'
    , 'lshw'
    , 'lsof'
    , 'ltrace'
    , 'lynx'
    , 'm4'
    , 'mesa-utils'
    , 'moreutils'
    , 'ncdu'
    , 'nmap'
    , 'nvme-cli'
    , 'plocate'
    , 'powertop'
    , 'procps'
    , 'psensor'
    , 'pssh'
    , 'pv'
    , 'pwgen'
    , 'pwman3'
    , 'read-edid'
    , 'rsnapshot'
    , 'rsyslog'
    , 'ruby-eventmachine'
    , 'ruby-faye-websocket'
    , 'ruby-sys-proctable'
    , 'screen'
    , 'secure-delete'
    , 'setserial'
    , 'smartmontools'
    , 'speedtest-cli'
    , 'sshfs'
    , 'strace'
    , 'stress'
    , 'sudo'
    , 'sysbench'
    , 'sysfsutils'
    , 'sysstat'
    # , 'tftp'                  # XXX missing from Trixie
    , 'telnet'
    , 'terminator'
    , 'time'
    , 'tmux'
    , 'tmux-plugin-manager'
    , 'tshark'
    , 'ulogd2'
    # , 'vinagre'               # XXX missing from Trixie
    , 'vrms'
    , 'w3m'
    , 'wakeonlan'
    , 'wavemon'
    , 'whois'
    , 'wireguard-tools'
    , 'wsmancli'
    , 'x11vnc'
    , 'xvfb'
    , 'xbacklight'
    , 'xinput-calibrator'
    , 'zsh' ]:
      tag => [ 'tag_admin', 'tag_debian_desktop', ];

    [ 'espeak-ng'
    , 'gnome-sound-recorder'
    , 'lame'
    , 'libasound2-plugins'
    , 'mumble'
    , 'pavucontrol'
    # , 'pavumeter'             # XXX missing from Trixie
    , 'qstopmotion'
    , 'shotcut'
    , 'simplescreenrecorder'
    , 'timidity'
    , 'vorbis-tools' ]:
      tag => [ 'tag_audio', 'tag_debian_desktop', ];

    [ 'bash'
    , 'bash-completion'
    , 'bridge-utils'
    , 'efibootmgr'
    , 'gdebi-core'
    , 'grub-efi-amd64-signed'
    , 'grub-efi-ia32-signed'
    , 'grub-efi-amd64-bin'
    , 'grub-efi-ia32-bin'
    , 'grub-pc'
    , 'grub-pc-bin'
    , 'mokutil'
    , 'ksh'
    , 'libglib2.0-bin'
    , 'libjffi-jni'    # needed by cryptomator
    , 'libpam-ccreds'
    , 'libpam-krb5'
    , 'libpam-ldapd'
    , 'libpam-modules'
    , 'libpam-runtime'
    , 'lvm2'
    , 'nano'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'pm-utils'
    , 'rng-tools-debian'
    , 'sbsigntool'
    , 'systemd'
    , 'systemd-ukify'
    # , 'tomoyo-tools'  # XXX missing from Trixie
    , 'udev'
    , 'udisks2'
    , 'vlan' ]:
      tag => [ 'tag_basic', 'tag_debian_desktop', ];

    [ 'debootstrap'
    , 'squashfs-tools'
    , 'systemd-container' ]:
      tag => [ 'tag_builder', 'tag_debian_desktop', ];

    [ 'gdm3'
    , 'i3'
    # , 'network-manager-fortisslvpn-gnome'     # XXX missing from Trixie
    , 'network-manager-openvpn-gnome'
    , 'network-manager-vpnc-gnome'
    , 'notify-osd'
    , 'onboard'
    , 'onboard-data'
    , 'python3-notify2'
    , 'shared-mime-info'
    , 'suckless-tools'
    , 'unclutter'
    , 'xmobar'
    , 'xmonad' ]:
      tag => [ 'tag_desktop', 'tag_debian_desktop', ];

    [ 'ack'
    , 'black'
    , 'build-essential'
    , 'bvi'
    , 'cdbs'
    , 'debconf-doc'
    , 'devscripts'
    , 'dh-make'
    , 'dpkg-dev'
    , 'dput'
    , 'elpa-flycheck'
    , 'fakeroot'
    , 'faketime'
    , 'gcc'
    , 'gdb'
    , 'gettext'
    , 'git-gui'
    , 'gitk'
    , 'glade'
    , 'gnupg'
    , 'kernel-wedge'
    , 'manpages-dev'
    , 'perl-doc'
    , 'pinfo'
    , 'python3-pydantic'
    , 'scdaemon'
    , 'shellcheck'
    , 'sloccount'
    , 'tcl9.0-doc'
    , 'tcl-thread'
    , 'tk9.0-doc'
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'tag_devel', 'tag_debian_desktop', ];

    [ 'dkms'
    , 'glx-alternative-mesa'
    # , 'libgl1-mesa-glx'               # XXX missing from Trixie
    , 'nvidia-settings'
    , 'update-glx'
    , 'xserver-xorg-core'
    , 'xserver-xorg-input-all'
    , 'xserver-xorg-input-evdev'
    , 'xserver-xorg-video-all' ]:
      tag => [ 'tag_drivers', 'tag_debian_desktop', ];

    [ 'tipp10' ]:
      tag => [ 'tag_education', 'tag_debian_desktop', ];

    [ 'mutt' ]:
      tag => [ 'tag_email', 'tag_debian_desktop', ];

    [ 'libvkd3d-shader1'
    # , 'virtualbox'                    # XXX missing from Trixie
    # , 'virtualbox-dkms'               # XXX missing from Trixie
    # , 'virtualbox-guest-utils'        # XXX missing from Trixie
    # , 'virtualbox-guest-x11'          # XXX missing from Trixie
    # , 'virtualbox-qt'                 # XXX missing from Trixie
    , 'vkd3d-compiler'
    # , 'wine-devel'                    # XXX missing from Trixie
    # , 'wine-devel-amd64'              # XXX missing from Trixie
    # , 'winehq-devel'                  # XXX missing from Trixie
    , 'winetricks' ]:
      tag => [ 'tag_emulation', 'tag_debian_desktop', ];

    [ 'b43-fwcutter'
    , 'firmware-b43-installer'
    , 'firmware-b43legacy-installer'
    , 'firmware-linux-free'
    # , 'firmware-microbit-micropython' # XXX missing from Trixie
    , 'isight-firmware-tools'
    , 'iucode-tool'
    , 'sigrok-firmware-fx2lafw'
    , 'ubertooth-firmware' ]:
      tag => [ 'tag_firmware_free', 'tag_debian_desktop', ];

    [ 'fontconfig'
    , 'fonts-motoya-l-cedar'
    , 'fonts-nanum'
    , 'fonts-roboto'
    , 'fonts-symbola'
    , 'fonts-ubuntu'
    , 'gnome-font-viewer'
    , 'ttf-bitstream-vera'
    , 'xfonts-terminus'
    , 'xfonts-utils' ]:
      tag => [ 'tag_fonts', 'tag_debian_desktop', ];

    [ 'aisleriot'
    , 'dosbox'
    , 'gcompris-qt'
    , 'gnome-games'
    , 'gnubg'
    , 'gnuchess'
    , 'khangman'
    , 'ktouch'
    , 'kwordquiz'
    , 'luola'
    , 'minetest'
    , 'neverball'
    , 'openttd'
    , 'qml-module-qtquick-dialogs'	        # needed by teamviewer
    , 'qml-module-qtquick-privatewidgets'	# needed by teamviewer
    , 'tuxmath'
    , 'tuxpaint'
    , 'tuxpaint-stamps-default'
    , 'xmoto' ]:
      tag => [ 'tag_games', 'tag_debian_desktop', ];

    [ 'dbus-x11'
    , 'gnome-applets'
    , 'gnome-power-manager'
    , 'gnome-user-docs'
    , 'notification-daemon' ]:
      tag => [ 'tag_gnome', 'tag_debian_desktop', ];

    [ 'blender'
    , 'breeze-icon-theme'	# wanted (not required) by kdenlive
    , 'dia'
    , 'dvgrab'
    , 'feh'
    , 'freecad'
    , 'geeqie'
    , 'gimp'
    , 'gimp-data-extras'
    # , 'gimp-plugin-registry'  # XXX missing from Trixie
    , 'godot3'
    , 'gthumb'
    , 'heif-gdk-pixbuf'         # Support for HEIF/HEIC Image formats
    , 'inkscape'
    , 'kdenlive'
    , 'kolourpaint'
    , 'krita'
    , 'krita-l10n'
    # , 'libsane'               # XXX missing from Trixie
    , 'meshlab'
    , 'mjpegtools'
    , 'mypaint'
    # , 'nautilus-image-converter'      # XXX missing from Trixie
    , 'obs-studio'
    , 'okular'
    , 'openscad'
    , 'openshot-qt'
    , 'pencil2d'
    , 'pitivi'
    , 'python3-lxml'
    , 'qiv'
    , 'sane-utils'
    , 'view3dscene'
    , 'xinit'
    , 'xsane' ]:
      tag => [ 'tag_graphics', 'tag_debian_desktop', ];

    [ 'irssi'
    , 'irssi-plugin-xmpp'
    , 'pidgin'
    , 'pidgin-plugin-pack' ]:
      tag => [ 'tag_instant_messaging', 'tag_debian_desktop', ];

    [ 'libportaudiocpp0'        # needed by xournalpp puavo-pkg
    , 'libuvc0' ]:              # needed by visualizer puavo-pkg
      tag => [ 'tag_libraries', 'tag_debian_desktop', ];

    # Add the -dev packages for those libraries we build ourselves.
    # These help Puavo developers in case these need installation.
    [ 'libcimcclient0-dev'
    , 'libcups2-dev'
    , 'libcupsfilters-dev'
    , 'libcupsimage2-dev'
    , 'libfontembed-dev'
    , 'libgail-3-dev'
    , 'libgtk2.0-dev'           # needed by lazarus-ide puavo-pkg
    , 'libgtk-3-dev'
    , 'libgtk-4-dev'
    , 'libmutter-16-dev'
    , 'libopenwsman-dev'
    , 'libwsman-clientpp-dev' ]:
      tag => [ 'tag_lib_devel', 'tag_debian_desktop', ];

    [ 'goobox'
    , 'gstreamer1.0-clutter-3.0'
    , 'gstreamer1.0-libav'
    , 'gstreamer1.0-plugins-bad'
    , 'gstreamer1.0-plugins-base'
    , 'gstreamer1.0-plugins-good'
    , 'gstreamer1.0-plugins-ugly'
    , 'gstreamer1.0-tools'
    , 'gstreamer1.0-vaapi'
    , 'handbrake'
    , 'handbrake-cli'
    , 'kaffeine'
    , 'libdvd-pkg'
    , 'libdvdread8t64'
    , 'recordmydesktop'
    , 'regionset'
    , 'smplayer'
    , 'vlc'
    , 'winff'
    , 'x264' ]:
      tag => [ 'tag_mediaplayer', 'tag_debian_desktop', ];

    [ 'ardour'
    , 'audacity'
    , 'fmit'
    , 'hydrogen'
    , 'lmms'
    , 'qsynth'
    , 'rosegarden'
    , 'solfege'
    , 'soundconverter'
    , 'tuxguitar' ]:
      tag => [ 'tag_music_making', 'tag_debian_desktop', ];

    [ 'amtterm'
    , 'etherwake'
    , 'nload'
    , 'usb-modeswitch-data' ]:
      tag => [ 'tag_network', 'tag_debian_desktop', ];

    [ 'calibre'
    # , 'freeplane'     # XXX Trixie
    , 'gummi'
    , 'impressive'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'libreoffice-librelogo'
    , 'retext'
    , 'scribus'
    , 'sent'
    , 'tellico'
    , 'texmaker'
    , 'thunderbird'
    , 'vym' ]:
      tag => [ 'tag_office', 'tag_debian_desktop', ];

    [ 'eject'
    , 'sound-juicer' ]:
      tag => [ 'tag_optical_media', 'tag_debian_desktop', ];

    [ 'cups-browsed'
    , 'cups-daemon'
    , 'cups-pk-helper'
    , 'gtklp' ]:
      tag => [ 'tag_printing', 'tag_debian_desktop', ];

    [ 'adb'
    # , 'aseba'                         # XXX missing from Trixie
    , 'avr-libc'
    , 'emacs'
    , 'eric'
    , 'eric-api-files'
    , 'fastboot'
    , 'fritzing'
    , 'gcc-avr'
    , 'geany'
    , 'idle'
    , 'idle-python3.13'
    , 'kturtle'
    , 'lokalize'
    , 'meld'
    , 'okteta'
    , 'pylint'
    , 'python3-doc'
    , 'python3-jsonpickle' # a dependency for
                           # http://meetedison.com/robot-programming-software/
    , 'python3-pip'
    , 'python3-pygame'
    , 'python-is-python3'
    , 'racket'
    , 'racket-doc'
    , 'sbcl'
    , 'scite'
    # , 'scratch'                       # XXX missing from Trixie
    , 'thonny' ]:
      tag => [ 'tag_programming', 'tag_debian_desktop', ];

    [ 'filezilla'
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
    , 'marble-qt'
    , 'openbabel'
    , 'pspp'
    , 'qgis'
    , 'step'
    , 'texlive-fonts-recommended'
    , 'texlive-latex-extra'
    , 'texlive-latex-recommended'
    , 'wxmaxima' ]:
      tag => [ 'tag_science', 'tag_debian_desktop', ];

    [ 'arc-theme'
    , 'deepin-icon-theme'
    , 'faenza-icon-theme'
    , 'gnome-icon-theme'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    , 'obsidian-icon-theme'
    , 'oxygen-icon-theme'
    , 'xscreensaver-data'
    , 'xscreensaver-gl'
    , 'yaru-theme-gnome-shell'
    , 'yaru-theme-gtk'
    , 'yaru-theme-icon' ]:
      tag => [ 'tag_themes', 'tag_debian_desktop', ];

    # desktop-packages relating to gnome and other, some of these
    # maybe belong to other categories or may be removed
    [ 'adwaita-icon-theme'
    , 'alsa-utils'
    , 'anacron'
    , 'appstream'
    , 'at-spi2-core'
    , 'avahi-autoipd'
    , 'avahi-daemon'
    , 'ayatana-indicator-bluetooth'
    , 'baobab'
    , 'bc'
    , 'bluetooth'
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
    , 'eog'
    , 'evince'
    , 'evolution'
    , 'festival'
    , 'festlex-poslex'
    , 'festvox-suopuhe-mv'			# Finnish TTS
    , 'file-roller'
    , 'fonts-cantarell'
    , 'fonts-dejavu-core'
    , 'fonts-freefont-ttf'
    , 'fonts-noto-color-emoji'                  # Chrome emoji support
    , 'foomatic-db-compressed-ppds'
    , 'foomatic-db-engine'
    , 'gcr'
    , 'gedit'
    , 'genisoimage'
    , 'ghostscript'
    , 'gjs'
    , 'gnome-accessibility-themes'
    , 'gnome-backgrounds'
    , 'gnome-bluetooth-sendto'
    , 'gnome-calculator'
    , 'gnome-color-manager'
    , 'gnome-clocks'
    , 'gnome-contacts'
    , 'gnome-control-center'
    , 'gnome-disk-utility'
    , 'gnome-keyring'
    , 'gnome-menus'
    , 'gnome-online-accounts'
    , 'gnome-screenshot'
    , 'gnome-session'
    , 'gnome-settings-daemon'
    , 'gnome-shell'
    , 'gnome-shell-extensions'
    , 'gnome-sushi'
    , 'gnome-system-monitor'
    , 'gnome-terminal'
    , 'gnome-themes-extra'
    , 'gnome-themes-extra-data'
    , 'gnome-tweaks'
    , 'gnome-user-share'
    , 'gnome-video-effects'
    , 'gsettings-desktop-schemas'
    , 'gstreamer1.0-alsa'
    , 'gstreamer1.0-libcamera'
    , 'gstreamer1.0-pulseaudio'
    , 'gucharmap'
    , 'gvfs-fuse'
    , 'hplip'
    , 'hunspell-en-us'
    , 'ibus'
    , 'ibus-anthy'
    , 'ibus-gtk3'
    , 'ibus-m17n'
    , 'ibus-pinyin'
    , 'ibus-table'
    , 'inputattach'
    , 'itstool'
    , 'kcalc'
    , 'laptop-detect'
    , 'libatk-adaptor'
    , 'libcamera-ipa'
    , 'libcamera-tools'
    , 'libcamera-v4l2'
    , 'libcamera0.4'
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
    , 'libreoffice-writer'
    , 'libsasl2-modules'
    , 'libttspico-utils' #German and English TTS
    , 'libxcb-xtest0' #dependency for Zoom
    , 'lightdm' # For all autologin sessions, such as InfoTV, ERS, USB Factory etc.
    , 'lightdm-autologin-greeter'
    , 'make'
    , 'memtest86+'
    , 'mousetweaks'
    , 'mutter'
    , 'nautilus'
    , 'network-manager'
    , 'network-manager-pptp'
    , 'network-manager-pptp-gnome'
    , 'openprinting-ppds'
    , 'orca'
    , 'pcmciautils'
    , 'pipewire-libcamera'
    , 'plymouth'
    , 'plymouth-themes'
    , 'printer-driver-all'
    , 'printer-driver-c2esp'
    , 'printer-driver-cups-pdf'
    , 'printer-driver-foo2zjs'
    , 'printer-driver-gutenprint'
    , 'printer-driver-hpijs'
    , 'printer-driver-min12xxw'
    , 'printer-driver-pnm2ppa'
    , 'printer-driver-ptouch'
    , 'printer-driver-pxljr'
    , 'printer-driver-sag-gdi'
    , 'printer-driver-splix'
    , 'pulseaudio'
    , 'pulseaudio-module-bluetooth'
    , 'qt5-style-kvantum'
    , 'qt5ct'
    , 'rfkill'
    , 'rtmpdump'
    , 'rxvt-unicode'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    , 'speech-dispatcher'
    , 'speech-dispatcher-festival'		# for Finnish TTS
    , 'speech-dispatcher-pico'			# for English and German TTS
    # , 'speedcrunch'                           # XXX missing from Trixie
    , 'ssh-askpass-gnome'
    , 'telepathy-idle'
    , 'tesseract-ocr'
    , 'totem'
    , 'transmission-gtk'
    , 'unzip'
    # , 'vino'                                  # XXX Trixie
    , 'wireless-tools'
    , 'wpasupplicant'
    , 'xdg-desktop-portal-gnome'                # for Nautilus
    , 'xdg-user-dirs'
    , 'xdg-user-dirs-gtk'
    , 'xdg-utils'
    , 'xkb-data'
    , 'xorg'
    , 'xterm'
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'zenity'
    , 'zip' ]:
      tag => [ 'tag_gnome_desktop', 'tag_debian_desktop', ];

    # some dependencies from puavo-pkg packages
    [ 'libftdi-dev'                       # flashprint
    , 'libftdi1'                          # mindplus
    , 'libftdi1-2'                        # flashprint
    , 'libhidapi-dev'                     # mindplus
    , 'libhidapi-hidraw0'                 # mindplus
    , 'libnss3-tools'                     # pyscrlink
    , 'libopencsg1'                       # openscad-nightly
    , 'libudev-dev'                       # flashprint
    , 'libusb-1.0-0-dev'                  # flashprint
    , 'libusb-dev'                        # flashprint
    , 'libqt5quickcontrols2-5'            # mafynetti
    , 'libqt5quicktemplates2-5'           # mafynetti
    , 'libqt5webenginewidgets5'           # promethean
    , 'libusb-0.1-4'                      # mindplus
    , 'python3-bluez'                     # pyscrlink
    , 'python3-cffi'                      # pyscrlink
    , 'python3-openssl'                   # pyscrlink
    , 'python3-pycparser'                 # pyscrlink
    , 'python3-websockets'                # pyscrlink
    , 'qml-module-qtquick-controls2'      # mafynetti
    , 'qml-module-qtquick-templates2'     # mafynetti
    ]:
      tag => [ 'tag_puavopkg', 'tag_debian_desktop', ];

    # [ 'anki'                          # XXX missing from Trixie
    [ 'bindfs'
    , 'binfmt-support'
    , 'blueman'
    , 'desktop-file-utils'
    , 'detox'
    , 'duplicity'
    , 'exfat-fuse'
    , 'flameshot'
    , 'fuse3'
    , 'gnome-network-displays'
    , 'ideviceinstaller'
    , 'idevicerestore'
    , 'jhead'
    , 'kamoso'
    , 'kde-spectacle'
    , 'libheif-examples'  # CLI-tools for converting HEIF media.
    , 'mc'
    , 'mousepad'
    , 'p7zip-full'
    , 'pass'
    , 'password-gorilla'
    , 'pdfarranger'
    , 'rename'
    , 'system-config-printer'
    , 'tlp'
    # , 'ubertooth'             # XXX missing from Trixie
    , 'unace'
    # , 'unionfs-fuse'    # Ekapeli might need this.    # XXX missing from Trixie
    , 'wimtools'
    , 'wmctrl'
    , 'xinput'
    , 'xxd'
    , 'zbarcam-gtk' ]:
      tag => [ 'tag_utils', 'tag_debian_desktop', ];

    [ 'qemu-system-x86'
    , 'virt-manager' ]:
      tag => [ 'tag_virtualization', 'tag_debian_desktop', ];

    [ 'bluefish'
    , 'ca-certificates-java'
    , 'chromium'
    , 'chromium-l10n'
    , 'epiphany-browser'
    , 'icedtea-netx'
    , 'liferea'
    , 'openjdk-25-jdk'
    , 'openjdk-25-jre'
    , 'php-cli'
    , 'php-sqlite3'
    , 'sqlite3' ]:
      tag => [ 'tag_web', 'tag_debian_desktop', ];

    'openboard':
      tag => [ 'tag_whiteboard', 'tag_debian_desktop', ];
  }

  $broadcom_sta_dkms_module = 'broadcom-sta/6.30.223.271'
  $nvidia_dkms_535_module   = 'nvidia-current/535.216.01'
  $r8168_module             = 'r8168/8.051.02'
  $virtualbox_module        = 'virtualbox/7.1.12'

  $all_dkms_modules =
    $::puavoimage_class ? {
      'exam'  => [ $broadcom_sta_dkms_module ],
      default => [ $broadcom_sta_dkms_module ]
                 # , $nvidia_dkms_535_module    # XXX Trixie
                 # , $r8168_module              # XXX Trixie
                 # , $virtualbox_module ]       # XXX Trixie
  }

  @packages::kernels::kernel_package {
    'default':
      dkms_modules => $all_dkms_modules,
      package_name => 'linux-image-6.12.48+deb13-amd64',
      version      => '6.12.48+deb13-amd64';

    'modern':
      dkms_modules => [],  # XXX what could work with this?
      package_name => 'linux-image-6.16.3+deb13-amd64',
      version      => '6.16.3+deb13-amd64';
  }

  # various contrib/non-free stuff, firmwares and such
  @package {
    'nautilus-dropbox':
      tag => [ 'tag_debian_desktop', 'tag_debian_desktop_nonfree', ];

    [ 'broadcom-sta-dkms'
    , 'intel-media-va-driver-non-free' # the free version seems to cause crashes in bullseye
    , 'nvidia-kernel-dkms'
    , 'r8168-dkms'
    , 'xserver-xorg-video-nvidia' ]:
      tag => [ 'tag_drivers', 'tag_debian_desktop_nonfree', ];

    [ 'amd64-microcode'
    , 'firmware-amd-graphics'
    , 'firmware-atheros'
    , 'firmware-bnx2'
    , 'firmware-bnx2x'
    , 'firmware-brcm80211'
    , 'firmware-cavium'
    , 'firmware-intel-sound'
    , 'firmware-iwlwifi'
    , 'firmware-libertas'
    , 'firmware-linux'
    , 'firmware-linux-nonfree'
    , 'firmware-misc-nonfree'
    , 'firmware-myricom'
    , 'firmware-netronome'
    , 'firmware-netxen'
    , 'firmware-qcom-media'
    , 'firmware-qcom-soc'
    , 'firmware-qlogic'
    , 'firmware-realtek'
    , 'firmware-samsung'
    , 'firmware-siano'
    , 'firmware-sof-signed'
    , 'firmware-ti-connectivity'
    , 'firmware-zd1211'
    , 'intel-microcode'
    , 'midisport-firmware' ]:
      ensure => present,
      tag    => [ 'tag_firmware_nonfree', 'tag_debian_nonfree', ];

    [ 'firmware-ipw2x00'
    , 'firmware-ivtv' ]:
      ensure => present,
      tag    => [ 'tag_firmware_nonfree_with_debconf', 'tag_debian_nonfree', ];

    'steam':
      tag => [ 'tag_games', 'tag_debian_desktop_nonfree', ];

    'scribus-doc':
      tag => [ 'tag_office', 'tag_debian_desktop_nonfree', ];

    'unrar':
      tag => [ 'tag_utils', 'tag_debian_nonfree', ];
  }

  # For some reason installing "wireguards-tools" prefers
  # to install some kernel packages we do not want.
  # Prevent this from happening by using "--no-install-recommends".
  Package['wireguard-tools'] {
    install_options => [ '--no-install-recommends' ],
  }
}
