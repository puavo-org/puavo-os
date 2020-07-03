class image::bundle::desktop {
  include ::autostart
  include ::blueman
  include ::chromium
  include ::desktop
  include ::desktop_cups
  include ::devilspie
  include ::disable_accounts_service
  include ::disable_unclutter
  include ::exec_restrictions
  include ::firefox
  include ::fontconfig
  include ::fuse
  include ::gdm
  include ::gnome_terminal
  include ::graphics_drivers
  include ::homedir_management
  include ::ibus
  include ::image::bundle::basic
  include ::kaffeine
  include ::keyutils
  # include ::ktouch                    # XXX buster
  include ::libdvdcss
  include ::libreoffice
  include ::network_manager
  include ::password_expiration
  include ::packages::languages::de
  include ::packages::languages::en
  include ::packages::languages::fi
  include ::packages::languages::fr
  include ::packages::languages::id
  include ::packages::languages::sv
  include ::picaxe_udev_rules
  include ::polkit_printers
  include ::puavo_pkg::packages
  # include ::pycharm	                # XXX pycharm needs to be packaged
  include ::run_once_on_desktop_session
  include ::supplementary_groups
  include ::tuxpaint
  include ::virtualbox
  include ::virtualbox::guest_additions
  include ::vym
  include ::wacom
  include ::wine
  include ::workaround_firefox_local_swf_bug
  include ::xorg

  Package <| tag == 'tag_debian_desktop'
          or tag == 'tag_debian_desktop_backports' |>
}
