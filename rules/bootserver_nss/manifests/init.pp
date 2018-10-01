class bootserver_nss {
  include ::puavo_conf

  file {
    '/etc/nscd.conf':
      source => 'puppet:///modules/bootserver_nss/nscd.conf';
  }

  ::puavo_conf::script {
    'setup_bootserver_nss':
      source => 'puppet:///modules/bootserver_nss/setup_bootserver_nss';
  }
}
