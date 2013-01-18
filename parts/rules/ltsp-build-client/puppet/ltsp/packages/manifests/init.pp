class packages {
  require apt::repositories,
          organisation_apt_repositories

  include packages::purged

  # install packages by default
  Package { ensure => latest, }

  define kernel_package_for_version ($package_tags) {
    $version = $title

    @package {
      [ "linux-headers-$version"
      , "linux-image-$version"
      , "linux-image-extra-$version" ]:
        tag => [ 'kernel', $package_tags, ]
    }
  }

  @package {
    [ 'dconf-tools'
    , 'epoptes'
    , 'gawk'
    , 'git'
    , 'iftop'
    , 'initramfs-tools'
    , 'iperf'
    , 'lynx'
    , 'm4'
    , 'pv'
    , 'sl'
    , 'sudo'
    , 'terminator'
    , 'tmux'
    , 'tshark'
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
    , 'grub-pc'
    , 'lvm2'
    , 'nfs-common'
    , 'openssh-client'
    , 'openssh-server'
    , 'vlan' ]:
      tag => [ 'basic', 'ubuntu', ];

    [ 'webmenu' ]:
      tag => [ 'desktop', 'opinsys', ];

    [ 'lightdm'
    , 'lightdm-gtk-greeter'
    , 'nautilus-dropbox'
    , 'ubuntu-restricted-extras'
    , 'ubuntu-standard'
    , 'xul-ext-mozvoikko'
    , 'xul-ext-ubufox' ]:
      tag => [ 'desktop', 'ubuntu', ];

    [ 'ack-grep'
    , 'build-essential'
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
    , 'unetbootin' ]:
      tag => [ 'devel', 'ubuntu', ];

    [ 'fglrx'
    , 'libgl1-mesa-glx'
    , 'nvidia-current'
    , 'nvidia-settings' ]:
      tag => [ 'drivers', 'ubuntu', ];

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

    [ 'firefox-locale-en'
    , 'hyphen-en-us'
    , 'kde-l10n-engb'
    , 'language-pack-en'
    , 'language-pack-gnome-en'
    , 'language-pack-kde-en'
    , 'libreoffice-help-en-gb'
    , 'libreoffice-l10n-en-gb'
    , 'libreoffice-l10n-en-za'
    , 'myspell-en-gb'
    , 'mythes-en-us'
    , 'thunderbird-locale-en-gb' ]:
      tag => [ 'language-en', 'ubuntu', ];

    [ 'firefox-locale-fi'
    , 'kde-l10n-fi'
    , 'language-pack-fi'
    , 'language-pack-gnome-fi'
    , 'language-pack-kde-fi'
    , 'libreoffice-help-fi'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-voikko'
    , 'myspell-fi'
    , 'thunderbird-locale-fi' ]:
      tag => [ 'language-fi', 'ubuntu', ];

    [ 'firefox-locale-sv'
    , 'gimp-help-sv'
    , 'kde-l10n-sv'
    , 'language-pack-gnome-sv'
    , 'language-pack-kde-sv'
    , 'language-pack-sv'
    , 'libreoffice-help-sv'
    , 'libreoffice-l10n-sv'
    , 'myspell-sv-se'
    , 'thunderbird-locale-sv-se' ]:
      tag => [ 'language-sv', 'ubuntu', ];

    [ 'xexit' ]:
      tag => [ 'ltsp', 'opinsys', ];

    [ 'ltsp-client'
    , 'ltsp-server' ]:
      tag => [ 'ltsp', 'ubuntu', ];

# XXX disable for now
#   [ 'libdvdcss2' ]:
#     tag => [ 'mediaplayer', ];

    [ 'spotify-client-qt' ]:
      tag => [ 'mediaplayer', ];

    [ 'banshee'
    , 'gnome-mplayer'
    , 'gstreamer1.0-clutter'
    , 'gstreamer1.0-libav'
    , 'gstreamer1.0-plugins-bad'
    , 'gstreamer1.0-plugins-base'
    , 'gstreamer1.0-plugins-good'
    , 'gstreamer1.0-plugins-ugly'
    , 'gstreamer1.0-tools'
    , 'kaffeine'
    , 'libdvdread4'
    , 'me-tv'
    , 'python-gst0.10'
    , 'vlc'
    , 'vlc-plugin-pulse'
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

# XXX disable for now
#   [ 'acroread'
#   , 'cmaptools' ]:
#     tag => [ 'office', ];

    [ 'libreoffice'
    , 'libreoffice-base'
    , 'libreoffice-calc'
    , 'libreoffice-impress'
    , 'libreoffice-writer'
    , 'scribus'
    , 'scribus-doc'
    , 'tellico'
    , 'thunderbird'
    , 'vym' ]:
      tag => [ 'office', 'ubuntu', ];

    [ 'cdparanoia'
    , 'cdrdao'
    , 'cue2toc'
    , 'rhythmbox-plugin-cdrecorder'
    , 'sound-juicer' ]:
      tag => [ 'optical_media', 'ubuntu', ];

    [ 'avrdude'
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

    [ 'puavo-wlanap' ]:
      tag => [ 'puavo', 'opinsys', ];

    [ 'ltsp-lightdm'
    , 'opinsys-ca-certificates'
    , 'puavo-ltsp-client'
    , 'puavo-ltsp-install'
    , 'puavo-register' ]:
      tag => [ 'puavo', 'opinsys', 'thinclient', ];

    [ 'vmware-view-client' ]:
      tag => [ 'remote_access', 'vmware-view-client', ];

    [ 'gftp-gtk'
    , 'lftp'
    , 'remmina'
    , 'smbclient'
    , 'ubuntuone-client'
    , 'wget' ]:
      tag => [ 'remote_access', 'ubuntu', ];

    [ 'googleearth' ]:
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

    [ 'liitu-themes' ]:
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
    , 'gdm'
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
    , 'gnome-shell'
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
    , 'kdepasswd'
    , 'khelpcenter4'
    , 'rarian-compat'
    , 'screenlets'
    , 'unace'
    , 'unrar' ]:
      tag => [ 'utils', 'ubuntu', ];

    [ 'google-talkplugin'
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

# XXX disabled for now
#   'mimio-studio':
#     tag => [ 'whiteboard-mimio', ];

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
    'precise': {}
    'quantal': {
      kernel_package_for_version {
        '3.6.6-999-generic':
          package_tags => 'opinsys';
      }
    }
  }
}
