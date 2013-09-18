class packages {
  require apt::repositories,
          organisation_apt_repositories

  include packages::purged

  # install packages by default
  Package { ensure => present, }

  define kernel_package_for_version ($package_tag='', $with_extra=true) {
    $version = $title

    $packages = $with_extra ? {
                  true  => [ "linux-headers-$version"
                           , "linux-image-$version"
                           , "linux-image-extra-$version" ],
                  false => [ "linux-headers-$version"
                           , "linux-image-$version" ],
                }

    @package {
      $packages:
        tag => $package_tag ? {
                 ''      => 'kernel',
                 default => [ 'kernel', $package_tag, ],
               },
    }
  }

  @package {
    [ 'elinks'
    , 'ethtool'
    , 'fping'
    , 'gawk'
    , 'git'
    , 'initramfs-tools'
    , 'iftop'
    , 'inotify-tools'
    , 'iperf'
    , 'libstdc++5'
    , 'lynx'
    , 'm4'
    , 'mlocate'
    , 'nmap'
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
    , 'x11vnc']:
      tag => [ 'admin', 'thinclient', 'ubuntu', ];

    [ 'clusterssh'
    , 'dconf-tools'
    , 'terminator'
    , 'vinagre' ]:
      tag => [ 'admin', 'ubuntu', ];

    [ 'spotify-client' ]:
      tag => [ 'audio', 'opinsys', ];

    [ 'libasound2-plugins'
    , 'pavucontrol'
    , 'pavumeter'
    , 'pulseaudio-esound-compat'
    , 'timidity' ]:
      tag => [ 'audio', 'ubuntu', ];

    [ 'bash'
    , 'bridge-utils'
    , 'btrfs-tools'
    , 'gdebi-core'
    , 'grub-pc'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'policykit-1'
    , 'rng-tools'
    , 'vlan' ]:
      tag => [ 'basic', 'ubuntu', ];

    [ 'webmenu' ]:
      tag => [ 'desktop', 'opinsys', ];

    [ 'lightdm'
    , 'lightdm-gtk-greeter'
    , 'nautilus-dropbox'
    , 'overlay-scrollbar'               # needed by accessibility stuff
    , 'ubuntu-restricted-extras'
    , 'ubuntu-standard'
    , 'xul-ext-mozvoikko'
    , 'xul-ext-ubufox' ]:
      tag => [ 'desktop', 'ubuntu', ];

    'nautilus-dropbox-dist':
      tag => [ 'desktop', 'opinsys', ];

    'nodejs-bundle':
      tag => [ 'devel', 'opinsys', ];

    [ 'ack-grep'
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
    , 'ruby-prof'
    , 'unetbootin'
    , 'translate-toolkit'
    , 'vim-nox' ]:
      tag => [ 'devel', 'ubuntu', ];

    [ 'bcmwl-kernel-source'
    , 'libgl1-mesa-glx'
    , 'linux-firmware'
    , 'nvidia-current'
    , 'nvidia-settings'
    , 'xserver-xorg-video-all' ]:
      tag => [ 'drivers', 'ubuntu', ];

    [ 'opinsys-linux-firmware' ]:
      tag => [ 'drivers', 'opinsys', ];

    [ 'wine' ]:
      tag => [ 'emulation', 'ubuntu', ];

    [ 'ttf-freefont'
    , 'ttf-mscorefonts-installer'
    , 'x-ttcidfont-conf' ]:
      tag => [ 'fonts', 'ubuntu', ];

    [ 'billard-gl'
    , 'cuyo'
    , 'extremetuxracer'
    , 'foobillard'
    , 'freeciv-client-gtk'
    , 'freecol'
    , 'frozen-bubble'
    , 'gbrainy'
    , 'gcompris'
    , 'gcompris-sound-en'
    , 'gcompris-sound-fi'
    , 'gcompris-sound-sv'
    , 'gnibbles'
    , 'gnome-mahjongg'
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
    , 'wormux'
    , 'xmoto' ]:
      tag => [ 'games', 'ubuntu', ];

    [ 'consolekit'
    , 'dbus-x11'
    , 'gnome-applets'
    , 'gnome-power-manager'
    , 'gnome-user-guide'
    , 'gnome-utils'
    , 'libgnome2-perl'
    , 'libgnomevfs2-bin'
    , 'libgnomevfs2-extra'
    , 'libreoffice-gnome'
    , 'notification-daemon'
    , 'thunderbird-gnome-support'
    , 'ubuntu-docs' ]:
      tag => [ 'gnome', 'ubuntu', ];

    [ 'blender'
    , 'dia'
    , 'dvgrab'
    , 'ffmpeg'
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
    , 'libsane-extras'
    , 'luciole'
    , 'mencoder'
    , 'mjpegtools'
    , 'mypaint'
    , 'nautilus-image-converter'
    , 'okular'
    , 'openshot'
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

    [ 'skype' ]:
      tag => [ 'instant_messaging', 'partner', ];

    [ 'emesene'
    , 'gobby'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack' ]:
      tag => [ 'instant_messaging', 'ubuntu', ];

    'language-pack-gnome-en':
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

    'language-pack-gnome-fi':
      tag => [ 'language-fi', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-fi'
    , 'kde-l10n-fi'
    , 'language-pack-fi'
    , 'language-pack-kde-fi'
    , 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko'
    , 'myspell-fi'
    , 'thunderbird-locale-fi' ]:
      tag => [ 'language-fi', 'ubuntu', ];

    'language-pack-gnome-sv':
      tag => [ 'language-sv', 'thinclient', 'ubuntu', ];

    [ 'firefox-locale-sv'
    , 'gimp-help-sv'
    , 'kde-l10n-sv'
    , 'language-pack-kde-sv'
    , 'language-pack-sv'
    , 'libreoffice-help-sv'
    , 'libreoffice-l10n-sv'
    , 'myspell-sv-se'
    , 'thunderbird-locale-sv-se' ]:
      tag => [ 'language-sv', 'ubuntu', ];

    [ 'autopoweroff'
    , 'xexit' ]:
      tag => [ 'ltsp', 'opinsys', ];

    [ 'ltsp-client'
    , 'ltsp-server' ]:
      tag => [ 'ltsp', 'ubuntu', ];

    [ 'libdvdcss2' ]:
      tag => [ 'mediaplayer', 'opinsys', ];

    [ 'spotify-client-qt' ]:
      tag => [ 'mediaplayer', ];

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
    , 'kaffeine'
    , 'kscd'
    , 'libdvdread4'
    , 'me-tv'
    , 'python-gst0.10'
    , 'vlc'
    , 'vlc-plugin-pulse'
    , 'x264'
    , 'xbmc' ]:
      tag => [ 'mediaplayer', 'ubuntu', ];

# XXX problems with these beasts
#    [ 'nagios-nrpe-plugin'
#    , 'nagios-nrpe-server'
#    , 'nagios-plugins-basic'
#    , 'nagios-plugins-extra'
#    , 'nagios-plugins-standard' ]:
#      tag => [ 'monitoring', 'ubuntu', ];

    [ 'ardour'
    , 'audacity'
    , 'denemo'
    , 'fmit'
    , 'hydrogen'
    , 'jokosher'
    , 'libavcodec-extra-53'
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

    [ 'acroread' ]:
      tag => [ 'office', 'opinsys', ];

    [ 'cmaptools' ]:
      tag => [ 'office', 'opinsys', ];

    [ 'librecad'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'libreoffice-calc'
    , 'libreoffice-impress'
    , 'libreoffice-writer'
    , 'scribus'
    , 'scribus-doc'
    , 'tellico'
    , 'thunderbird'
    , 'vym'
    , 'qcad' ]:
      tag => [ 'office', 'ubuntu', ];

    [ 'cdparanoia'
    , 'cdrdao'
    , 'cue2toc'
    , 'rhythmbox-plugin-cdrecorder'
    , 'sound-juicer' ]:
      tag => [ 'optical_media', 'ubuntu', ];

    [ 'arduino'
    , 'arduino-mk'
    , 'avr-libc'
    , 'basic256'
    , 'eclipse'
    , 'emacs23'
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

    [ 'puavo-load-balancer'
    , 'puavo-sharedir-client'
    , 'puavo-wlanap' ]:
      tag => [ 'puavo', 'opinsys', ];

    [ 'ltsp-lightdm'
    , 'opinsys-ca-certificates'
    , 'puavo-client'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-monitor'
    , 'puavo-vpn-client' ]:
      tag => [ 'puavo', 'opinsys', 'thinclient', ];

    [ 'icaclient'       # icaclient actually depends on libmotif4
    , 'libmotif4' ]:
      tag => [ 'remote_access', 'opinsys', ];

    [ 'vmware-view-client' ]:
      tag => [ 'remote_access', 'partner', ];

    [ 'gftp-gtk'
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'ubuntuone-client'
    , 'unison-gtk'
    , 'wget' ]:
      tag => [ 'remote_access', 'ubuntu', ];

    [ 'googleearth'
    , 'av4kav' ]:
      tag => [ 'science', 'opinsys', ];

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
    , 'marble'
    , 'mandelbulber'
    , 'pspp'
    , 'rkward'
    , 'stellarium'
    , 'wxmaxima' ]:
      tag => [ 'science', 'ubuntu', ];

    [ 'faenza-icon-theme'
    , 'liitu-themes' ]:
      tag => [ 'themes', 'opinsys', ];

    [ 'breathe-icon-theme'
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
    , 'ubuntu-mono'
    , 'ubuntu-wallpapers'
    , 'ubuntu-wallpapers-extra'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'ubuntu', ];

    # the dependencies of ubuntu-gnome-desktop package
    # without a few packages that we do not want
    [ 'abiword'
    , 'acpi-support'
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
    , 'bluez-gstreamer'
    , 'brasero'
    , 'brltty'
    , 'ca-certificates'
    , 'cheese'
    , 'cups'
    , 'cups-bsd'
    , 'cups-client'
    # , 'deja-dup'              # not needed
    , 'dmz-cursor-theme'
    , 'doc-base'
    , 'empathy'
    , 'eog'
    , 'epiphany-browser'
    , 'evince'
    , 'evolution'
    , 'example-content'
    , 'file-roller'
    , 'fonts-cantarell'
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
    , 'foomatic-filters'
    , 'gcalctool'
    , 'gcc'
    , 'gcr'
    # , 'gdm'                   # not needed
    , 'gedit'
    , 'genisoimage'
    , 'ghostscript-x'
    , 'gjs'
    , 'gnome-accessibility-themes'
    , 'gnome-backgrounds'
    , 'gnome-bluetooth'
    , 'gnome-color-manager'
    , 'gnome-contacts'
    , 'gnome-control-center'
    , 'gnome-dictionary'
    , 'gnome-disk-utility'
    , 'gnome-font-viewer'
    , 'gnome-games'
    , 'gnome-icon-theme-extras'
    , 'gnome-icon-theme-full'
    , 'gnome-icon-theme-symbolic'
    , 'gnome-keyring'
    , 'gnome-media'
    , 'gnome-menus'
    , 'gnome-online-accounts'
    , 'gnome-orca'
    , 'gnome-packagekit'
    , 'gnome-panel'
    , 'gnome-screensaver'
    , 'gnome-screenshot'
    , 'gnome-search-tool'
    , 'gnome-session'
    , 'gnome-session-canberra'
    , 'gnome-settings-daemon'
    # , 'gnome-shell'           # not needed
    , 'gnome-sushi'
    , 'gnome-system-log'
    , 'gnome-system-monitor'
    , 'gnome-terminal'
    , 'gnome-themes-standard'
    , 'gnome-tweak-tool'
    , 'gnome-user-share'
    , 'gnome-video-effects'
    , 'gnumeric'
    , 'gsettings-desktop-schemas'
    , 'gstreamer0.10-alsa'
    , 'gstreamer0.10-plugins-base-apps'
    , 'gstreamer0.10-pulseaudio'
    , 'gstreamer1.0-alsa'
    , 'gstreamer1.0-plugins-base-apps'
    , 'gstreamer1.0-pulseaudio'
    , 'gucharmap'
    , 'gvfs-bin'
    , 'gvfs-fuse'
    , 'gwibber'
    , 'hplip'
    , 'ibus'
    , 'ibus-gtk3'
    , 'ibus-pinyin'
    , 'ibus-pinyin-db-android'
    , 'ibus-table'
    , 'im-switch'
    , 'indicator-datetime'
    , 'indicator-printers'
    , 'inputattach'
    , 'itstool'
    , 'kerneloops-daemon'
    , 'laptop-detect'
    , 'libatk-adaptor'
    , 'libgail-common'
    , 'libgd2-xpm'
    , 'libnotify-bin'
    , 'libnss-mdns'
    , 'libpam-ck-connector'
    , 'libpam-gnome-keyring'
    , 'libproxy1-plugin-gsettings'
    , 'libproxy1-plugin-networkmanager'
    , 'libqt4-sql-sqlite'
    , 'libsasl2-modules'
    , 'libwmf0.2-7-gtk'
    , 'libxp6'
    , 'linux-headers-generic-pae'
    , 'make'
    , 'mesa-utils'
    , 'metacity'
    , 'mousetweaks'
    , 'mutter'
    , 'nautilus'
    , 'nautilus-sendto'
    # , 'nautilus-share'                        # this forces
                                                # software-properties-gtk
                                                # to be installed
    , 'network-manager-gnome'
    , 'network-manager-pptp'
    , 'network-manager-pptp-gnome'
    , 'network-manager-openvpn'
    , 'network-manager-openvpn-gnome'
    , 'onboard'
    , 'openprinting-ppds'
    , 'pcmciautils'
    # , 'plymouth-theme-ubuntu-gnome-logo'      # not needed, we have our own
    # , 'plymouth-theme-ubuntu-gnome-text'      # plymouth theme
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
    , 'pulseaudio-module-gconf'
    , 'pulseaudio-module-x11'
    , 'python-cloudfiles'
    , 'rfkill'
    , 'rhythmbox'
    , 'rhythmbox-plugin-magnatune'
    , 'rhythmbox-ubuntuone'
    , 'seahorse'
    , 'shotwell'
    , 'simple-scan'
    # , 'software-properties-gtk'       # purged elsewhere
    , 'speech-dispatcher'
    , 'ssh-askpass-gnome'
    , 'telepathy-idle'
    , 'totem'
    # , 'tracker'                       # purged elsewhere
    , 'transmission-gtk'
    , 'ttf-dejavu-core'
    , 'ttf-indic-fonts-core'
    , 'ttf-punjabi-fonts'
    , 'ttf-ubuntu-font-family'
    , 'ttf-wqy-microhei'
    , 'ubuntu-drivers-common'
    , 'ubuntu-extras-keyring'
    , 'ubuntu-gnome-default-settings'
    , 'unzip'
    , 'usb-creator-gtk'
    , 'vino'
    , 'whoopsie'
    , 'wireless-tools'
    , 'wpasupplicant'
    , 'xcursor-themes'
    , 'xdg-user-dirs'
    , 'xdg-user-dirs-gtk'
    , 'xdg-utils'
    , 'xdiagnose'
    , 'xkb-data'
    , 'xorg'
    , 'xterm'
    , 'yelp'
    , 'yelp-tools'
    , 'yelp-xsl'
    , 'zenity'
    , 'zip' ]:
      tag => [ 'ubuntu-gnome-desktop', 'ubuntu', ];

    [ 'desktop-file-utils'
    , 'fuse-utils'
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

    [ 'google-talkplugin'
    , 'oracle-java'
    , 'xul-ext-flashblock' ]:
      tag => [ 'web', 'opinsys', ];

    [ 'adobe-flashplugin' ]:
      tag => [ 'web', 'partner', ];

    [ 'bluefish'
    , 'chromium-browser'
    , 'firefox'
    , 'gecko-mediaplayer'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-6-jdk'
    , 'openjdk-6-jre' ]:
      tag => [ 'web', 'ubuntu', ];

   [ 'open-sankore', ]:
      tag => [ 'whiteboard', 'ubuntu', ];

   [ 'eleet'
   , 'leap' ]:
      tag => [ 'whiteboard', 'opinsys', ];

   [ 'mimio-studio', ]:
    tag => [ 'whiteboard-mimio', 'opinsys', ];

   [ 'ebeam-edu', ]:
    tag => [ 'whiteboard-ebeam', 'opinsys', ];
  
# XXX disabled for now
#   [ 'activaid'
#   , 'activdriver'
#   , 'activhwr-fi'
#   , 'activhwr-sv'
#   , 'activinspire'
#   , 'activinspire-help-en-gb'
#   , 'activinspire-help-fi'
#   , 'activinspire-help-sv'
#   , 'activ-meta-fi'
#   , 'activresources-core-en'
#   , 'activresources-core-fi'
#   , 'activresources-core-sv'
#   , 'activtools' ]:
#     tag => [ 'whiteboard-promethean', ];

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
      tag => [ 'whiteboard-smartboard', 'opinsys', ];
  }

  case $lsbdistcodename {
    'quantal': {
      kernel_package_for_version {
        [ '3.8.13.opinsys1'
        , '3.10.9.opinsys1'  ]:
          package_tag => 'opinsys',
          with_extra  => false;
      }
    }
  }
}

