class image::bundle::desktop {
  # include ::acroread			# XXX needs fixing for Debian
  include ::chrome
  include ::chromium
  include ::desktop
  include ::disable_accounts_service
  include ::disable_geoclue
  include ::firefox
  include ::fontconfig
  include ::gnome_terminal
  include ::graphics_drivers
  include ::image::bundle::basic
  include ::kaffeine
  include ::keyutils
  include ::ktouch
  # include ::libreoffice		# XXX needs fixing for Debian
  include ::network_manager
  # include ::pycharm	                # XXX pycharm needs to be packaged
  include ::supplementary_groups
  # include ::tuxpaint	                # XXX needs fixing for Debian
  include ::wacom
  include ::workaround_firefox_local_swf_bug
  # include ::xexit	                # XXX perhaps unneeded?
}
