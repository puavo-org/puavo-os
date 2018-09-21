class image::bundle::desktop {
  include ::blueman
  include ::chrome
  include ::chromium
  include ::cups
  include ::desktop
  include ::disable_accounts_service
  include ::disable_geoclue
  include ::firefox
  include ::fontconfig
  include ::gnome_terminal
  include ::graphics_drivers
  include ::homedir_management
  include ::ibus
  include ::image::bundle::basic
  include ::kaffeine
  include ::keyutils
  include ::ktouch
  include ::libdvdcss
  include ::libreoffice
  include ::network_manager
  include ::notify_changelog
  include ::password_expiration
  # include ::pycharm	                # XXX pycharm needs to be packaged
  include ::smartboard
  include ::supplementary_groups
  include ::ti_nspire_cx_cas
  include ::tuxpaint
  include ::wacom
  include ::wine
  include ::workaround_firefox_local_swf_bug
  include ::xorg
}
