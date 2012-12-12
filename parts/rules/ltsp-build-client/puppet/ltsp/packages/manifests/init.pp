class packages {
  include apt

  # install packages by default
  Package { ensure => present, }

  @package {
    [ 'dconf-tools'
    , 'gawk'
    , 'git'
    , 'lynx'
    , 'sl'
    , 'sudo'
    , 'tmux'
    , 'tshark' ]:
      tag => [ 'admin', 'ubuntu', ];

    [ 'libasound2-plugins'
    , 'pavucontrol'
    , 'pavumeter'
    , 'pulseaudio'
    , 'pulseaudio-esound-compat'
    , 'pulseaudio-module-gconf'
    , 'pulseaudio-module-x11'
    , 'rhythmbox'
    , 'timidity' ]:
      tag => [ 'audio', 'ubuntu', ];

    [ 'bash'
    , 'bridge-utils'
    , 'btrfs-tools'
    , 'libnss-extrausers'
    , 'libnss-ldapd'
    , 'libpam-ldapd'
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
    , 'nautilus'
    , 'nautilus-dropbox'
    , 'ubuntu-gnome-desktop'
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
    , 'gnupg'
    , 'libssl-dev'
    , 'manpages-dev'
    , 'perl-doc'
    , 'pinfo'
    , 'ruby-prof'
    , 'unetbootin' ]:
      tag => [ 'devel', 'ubuntu', ];

    [ 'wine' ]:
      tag => [ 'emulation', 'ubuntu', ];

    [ 'ttf-dejavu-core'
    , 'ttf-freefont'
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
    , 'gnome-games'
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
    , 'gnome-control-center'
    , 'gnome-media'
    , 'gnome-panel'
    , 'gnome-power-manager'
    , 'gnome-screensaver'
    , 'gnome-terminal'
    , 'gnome-user-guide'
    , 'gnome-utils'
    , 'gvfs-fuse'
    , 'libgnome2-perl'
    , 'libgnomevfs2-bin'
    , 'libgnomevfs2-extra'
    , 'libpam-gnome-keyring'
    , 'libreoffice-gnome'
    , 'metacity'
    , 'network-manager-gnome'
    , 'notification-daemon'
    , 'ssh-askpass-gnome'
    , 'thunderbird-gnome-support'
    , 'ubuntu-docs'
    , 'yelp' ]:
      tag => [ 'gnome', 'ubuntu', ];

    [ 'blender'
    , 'cheese'
    , 'dia'
    , 'dvgrab'
    , 'eog'
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
    , 'simple-scan'
    , 'stopmotion'
    , 'synfig'
    , 'synfigstudio'
    , 'xsane'
    , 'xzoom' ]:
      tag => [ 'graphics', 'ubuntu', ];

    [ 'skype' ]:
      tag => [ 'instant_messaging', 'partner', ];

    [ 'emesene'
    , 'empathy'
    , 'gobby'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack' ]:
      tag => [ 'instant_messaging', 'ubuntu', ];

    [ 'gucharmap'
    , 'im-switch' ]:
      tag => [ 'languages', 'ubuntu', ];

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

    [ 'ltsp-client'
    , 'ltsp-server' ]:
      tag => [ 'ltsp', 'ubuntu', ];

    [ 'libdvdcss2' ]:
      tag => [ 'mediaplayer', ];

    [ 'spotify-client-qt' ]:
      tag => [ 'mediaplayer', ];

    [ 'banshee'
    , 'gnome-mplayer'
    , 'gstreamer1.0-alsa'
    , 'gstreamer1.0-clutter'
    , 'gstreamer1.0-libav'
    , 'gstreamer1.0-plugins-bad'
    , 'gstreamer1.0-plugins-base'
    , 'gstreamer1.0-plugins-good'
    , 'gstreamer1.0-plugins-ugly'
    , 'gstreamer1.0-pulseaudio'
    , 'gstreamer1.0-tools'
    , 'kaffeine'
    , 'libdvdread4'
    , 'me-tv'
    , 'python-gst0.10'
    , 'totem'
    , 'vlc'
    , 'vlc-plugin-pulse' ]:
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

    [ 'acroread'
    , 'cmaptools' ]:
      tag => [ 'office', ];

    [ 'evince'
    , 'ghostscript-x'
    , 'libreoffice'
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

    [ 'brasero'
    , 'cdparanoia'
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

    [ 'vmware-view-client' ]:
      tag => [ 'remote_access', 'vmware-view-client', ];

    [ 'gftp-gtk'
    , 'lftp'
    , 'smbclient'
    , 'ubuntuone-client'
    , 'wget' ]:
      tag => [ 'remote_access', 'ubuntu', ];

    [ 'googleearth' ]:
      tag => [ 'science', ];

    [ 'atomix'
    , 'celestia'
    , 'celestia-common-nonfree'
    , 'celestia-gnome'
    , 'drgeo'
    , 'drgeo-doc'
    , 'gcalctool'
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
    , 'pspp'
    , 'rkward'
    , 'stellarium'
    , 'wxmaxima' ]:
      tag => [ 'science', 'ubuntu', ];

    [ 'liitu-themes' ]:
      tag => [ 'themes', 'opinsys', ];

    [ 'breathe-icon-theme'
    , 'gnome-icon-theme'
    , 'gnome-themes-extras'
    , 'gnome-themes-standard'
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
    , 'xcursor-themes'
    , 'xkb-data'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'ubuntu', ];

    [ 'alsa-utils'
    , 'bc'
    , 'desktop-file-utils'
    , 'file-roller'
    , 'fuse-utils'
    , 'gconf-editor'
    , 'gedit'
    , 'gkbd-capplet'
    , 'kdepasswd'
    , 'khelpcenter4'
    , 'onboard'
    , 'rarian-compat'
    , 'screenlets'
    , 'seahorse'
    , 'unace'
    , 'unrar'
    , 'unzip'
    , 'xdg-utils'
    , 'xterm'
    , 'zenity'
    , 'zip' ]:
      tag => [ 'utils', 'ubuntu', ];

    [ 'google-talkplugin' ]:
      tag => [ 'web', ];

    [ 'adobe-flashplugin' ]:
      tag => [ 'web', 'partner', ];

    [ 'chromium-browser'
    , 'firefox'
    , 'gecko-mediaplayer'
    , 'icedtea-7-plugin'
    , 'liferea'
    , 'openjdk-6-jdk'
    , 'openjdk-6-jre' ]:
      tag => [ 'web', 'ubuntu', ];

    [ 'walma-screenshot' ]:
      tag => [ 'whiteboard-opinsys', 'opinsys', ];

    [ 'activaid'
    , 'activdriver'
    , 'activhwr-fi'
    , 'activhwr-sv'
    , 'activinspire'
    , 'activinspire-help-en-gb'
    , 'activinspire-help-fi'
    , 'activinspire-help-sv'
    , 'activ-meta-fi'
    , 'activresources-core-en'
    , 'activresources-core-fi'
    , 'activresources-core-sv'
    , 'activtools' ]:
      tag => [ 'whiteboard-promethean', ];

    [ 'nwfermi'
    , 'smart-activation'
    , 'smart-common'
    , 'smart-gallerysetup'
    , 'smart-hwr'
    , 'smart-languagesetup'
    , 'smart-notebook'
    , 'smart-product-drivers' ]:
      tag => [ 'whiteboard-smartboard', ];

    'mimio-studio':
      tag => [ 'whiteboard-mimio', ];
  }

  # keep these packages out, we do not want these
  @package {
    'nscd':
      ensure => purged,
      tag    => [ 'basic', 'ubuntu', ];
  }

  # XXX it would be nice if these were turned on simply if some package
  # XXX from these repositories is asked to be installed
  # define some apt repositories for use
  @apt::repository {
    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
