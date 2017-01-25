class bootserver_cron {
  file {
    '/etc/cron.d/fix-homedir-permissions':
      mode    => '0644',
      require => File['/usr/local/sbin/puavo-fix-homedir-permissions'],
      source  => 'puppet:///modules/bootserver_cron/fix-homedir-permissions.cron';

    '/etc/cron.d/fstrim':
      mode    => '0644',
      source  => 'puppet:///modules/bootserver_cron/fstrim.cron';

    '/etc/cron.d/remove-cups-jobs':
      mode    => '0644',
      source  => 'puppet:///modules/bootserver_cron/remove-cups-jobs.cron';

    '/usr/local/sbin/puavo-fix-homedir-permissions':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_cron/puavo-fix-homedir-permissions';
  }

  # XXX old stuff, may be removed once this has been removed from everywhere
  file {
    '/etc/cron.d/img-sync':
      ensure => absent;
  }
}
