class sysv::policy-rc {
  file {
    '/usr/sbin/policy-rc.d':
      mode   => 755,
      source => 'puppet:///modules/sysv/policy-rc.d';
  }
}
