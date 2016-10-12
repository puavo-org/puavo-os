class bootserver_cron {
  file {
    '/etc/cron.d/fstrim':
      mode    => 0644,
      source  => 'puppet:///modules/bootserver_cron/fstrim.cron';
    '/etc/cron.d/remove-cups-jobs':
      mode    => 0644,
      source  => 'puppet:///modules/bootserver_cron/remove-cups-jobs.cron';
  }

  # XXX old stuff, may be removed once this has been removed from everywhere
  file {
    '/etc/cron.d/img-sync':
      ensure => absent;
  }
}
