class packages {
  @package {
    [ 'gawk'
    , 'git'
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
    , 'nslcd'
    , 'openssh-client'
    , 'openssh-server'
    , 'vlan' ]:
      tag => [ 'basic', 'ubuntu', ];

    [ 'nautilus'
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

    [ 'latex-xft-fonts'
    , 'ttf-dejavu-core'
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
    , 'gnome-about'
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
    , 'libreoffice.org-gnome'
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
    , 'xsane' ]:
      tag => [ 'graphics', 'ubuntu', ];

    [ 'emesene'
    , 'empathy'
    , 'gobby'
    , 'pidgin'
    , 'pidgin-libnotify'
    , 'pidgin-plugin-pack'
    , 'skype' ]:
      tag => [ 'instant_messaging', 'ubuntu', ];

    [ 'gucharmap'
    , 'im-switch' ]:
      tag => [ 'languages', 'ubuntu', ];

    [ 'firefox-locale-en'
    , 'kde-l10n-engb'
    , 'language-pack-en'
    , 'language-pack-gnome-en'
    , 'language-pack-kde-en'
    , 'language-support-en'
    , 'language-support-writing-en'
    , 'libreoffice.org-help-en-gb'
    , 'libreoffice.org-hyphenation-en-us'
    , 'libreoffice.org-l10n-en-gb'
    , 'libreoffice.org-l10n-en-za'
    , 'libreoffice.org-thesaurus-en-au'
    , 'libreoffice.org-thesaurus-en-us'
    , 'myspell-en-gb'
    , 'thunderbird-locale-en-gb' ]:
      tag => [ 'language-en', 'ubuntu', ];

    [ 'firefox-locale-fi'
    , 'gnome-user-guide-fi'
    , 'kde-l10n-fi'
    , 'language-pack-fi'
    , 'language-pack-gnome-fi'
    , 'language-pack-kde-fi'
    , 'language-support-fi'
    , 'language-support-writing-fi'
    , 'libreoffice.org-help-fi'
    , 'libreoffice.org-l10n-fi'
    , 'libreoffice.org-voikko'
    , 'myspell-fi'
    , 'thunderbird-locale-fi' ]:
      tag => [ 'language-fi', 'ubuntu', ];

    [ 'firefox-locale-sv'
    , 'gimp-help-sv'
    , 'gnome-user-guide-sv'
    , 'kde-l10n-sv'
    , 'language-pack-gnome-sv'
    , 'language-pack-kde-sv'
    , 'language-pack-sv'
    , 'language-support-sv'
    , 'language-support-writing-sv'
    , 'libreoffice.org-help-sv'
    , 'libreoffice.org-l10n-sv'
    , 'myspell-sv-se'
    , 'thunderbird-locale-sv-se' ]:
      tag => [ 'language-sv', 'ubuntu', ];

    [ 'ltsp-client'
    , 'ltsp-server' ]:
      tag => [ 'ltsp', 'ubuntu', ];

    [ 'banshee'
    , 'gnome-mplayer'
    , 'gstreamer0.10-alsa'
    , 'gstreamer0.10-ffmpeg'
    , 'gstreamer0.10-fluendo-mp3'
    , 'gstreamer0.10-fluendo-mpegdemux'
    , 'gstreamer0.10-plugins-bad-multiverse'
    , 'gstreamer0.10-plugins-base-apps'
    , 'gstreamer0.10-plugins-ugly'
    , 'gstreamer0.10-plugins-ugly-multiverse'
    , 'gstreamer0.10-pulseaudio'
    , 'kaffeine'
    , 'libdvdcss2'
    , 'libdvdread4'
    , 'me-tv'
    , 'python-gst0.10'
    , 'spotify-client-qt'
    , 'totem'
    , 'vlc'
    , 'vlc-plugin-pulse' ]:
      tag => [ 'mediaplayer', 'ubuntu', ];

    [ 'nagios-nrpe-plugin'
    , 'nagios-nrpe-server'
    , 'nagios-plugins-basic'
    , 'nagios-plugins-extra'
    , 'nagios-plugins-standard' ]:
      tag => [ 'monitoring', 'ubuntu', ];

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
    , 'soundconvert'
    , 'sweep'
    , 'tuxguitar' ]:
      tag => [ 'music_making', 'ubuntu', ];

    [ 'acroread'
    , 'cmaptools'
    , 'evince'
    , 'ghostscript-x'
    , 'libreoffice.org'
    , 'libreoffice.org-base'
    , 'libreoffice.org-calc'
    , 'libreoffice.org-hyphenation'
    , 'libreoffice.org-impress'
    , 'libreoffice.org-writer'
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
    , 'kdewebdev-doc-html'
    , 'kompare'
    , 'kompozer'
    , 'kturtle'
    , 'netbeans'
    , 'pyqt4-dev-tools'
    , 'python-doc'
    , 'python-profiler'
    , 'python-pygame'
    , 'qt4-designer'
    , 'qt4-doc'
    , 'quanta'
    , 'scratch'
    , 'spe' ]:
      tag => [ 'programming', 'ubuntu', ];

    [ 'gftp-gtk'
    , 'lftp'
    , 'smbclient'
    , 'tsclient'
    , 'ubuntuone-client'
    , 'wget'
    , 'vmware-view-client' ]:
      tag => [ 'remote_access', 'ubuntu', ];

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
    , 'googleearth'
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

    [ 'opinsys-images' ]:
      tag => [ 'themes', 'opinsys', ];

    [ 'breathe-icon-theme'
    , 'gnome-icon-theme'
    , 'gnome-theme-almond'
    , 'gnome-themes'
    , 'gnome-themes-extras'
    , 'gnome-themes-more'
    , 'gnome-themes-selected'
    , 'gnome-themes-ubuntu'
    , 'gtk2-engines'
    , 'gtk2-engines-pixbuf'
    , 'human-theme'
    , 'kdelibs-data'
    , 'light-themes'
    , 'openclipart'
    , 'pidgin-themes'
    , 'tangerine-icon-theme'
    , 'screensaver-default-images'
    , 'ubuntu-wallpapers'
    , 'ubuntu-wallpapers-extra'
    , 'xcursor-themes'
    , 'xkb-data'
    , 'xscreensaver-data'
    , 'xscreensaver-data-extra' ]:
      tag => [ 'themes', 'ubuntu', ];

    [ 'alsa-utils'
    , 'bc'
    , 'deskbar-applet'
    , 'desktop-file-utils'
    , 'file-roller'
    , 'fuse-utils'
    , 'gconf-editor'
    , 'gedit'
    , 'gkbd-capplet'
    , 'kdepasswd'
    , 'khelpcenter'
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

    [ 'adobe-flashplugin'
    , 'chromium-browser'
    , 'emilda-print'
    , 'firefox'
    , 'gecko-mediaplayer'
    , 'google-talkplugin'
    , 'liferea'
    , 'prism'
    , 'sun-java6-bin'
    , 'sun-java6-jre'
    , 'sun-java6-plugin'
    , 'xul-ext-flashblock' ]:
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
}
