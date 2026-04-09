class ers_abitti2 {
  include ::munin
  include ::packages

  file {
    '/etc/munin/plugins/abitti_status':
      mode    => '0755',
      require => Package['munin-node'],
      source  => 'puppet:///modules/ers_abitti2/etc_munin_plugins_abitti_status';

    '/etc/munin/plugin-conf.d/abitti':
      require => Package['munin-node'],
      source  => 'puppet:///modules/ers_abitti2/etc_munin_plugin-conf_d_abitti';
  }

  Package <| title == munin-node |>
}
