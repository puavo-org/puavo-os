class gnome_shell_extensions::ding {
  include ::gnome_shell_extensions

  ::gnome_shell_extensions::add_extension {
    'ding@rastersoft.com': ;
  }

  file {
    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/createThumbnail.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/app/createThumbnail.js';

    '/usr/share/gnome-shell/extensions/ding@rastersoft.com/app/ding.js':
      mode    => '0755',
      require => ::Gnome_shell_extensions::Add_extension['ding@rastersoft.com'],
      source  => 'puppet:///modules/gnome_shell_extensions/ding@rastersoft.com/app/ding.js';
  }
}
