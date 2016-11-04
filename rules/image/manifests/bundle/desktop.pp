class image::bundle::desktop {
  # include ::acroread			# XXX needs fixing for Debian
  include ::chromium
  include ::desktop
  include ::disable_accounts_service
  include ::disable_geoclue
  # include ::firefox			# XXX iceweasel in Debian
  include ::fontconfig
  include ::gnome_terminal
  include ::graphics_drivers
  include ::image::bundle::basic
  include ::kaffeine
  include ::keyutils
  include ::ktouch
  include ::laptop_mode_tools
  # include ::libreoffice		# XXX needs fixing for Debian
  include ::network_manager
  # include ::pycharm	                # XXX pycharm needs to be packaged
  # include ::tuxpaint	                # XXX needs fixing for Debian
  include ::wacom
  include ::workaround_firefox_local_swf_bug
  # include ::xexit	                # XXX perhaps unneeded?
}
