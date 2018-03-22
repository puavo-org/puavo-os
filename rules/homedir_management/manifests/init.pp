class homedir_management {
  include ::puavo_conf

  file {
    '/etc/X11/Xsession.d/49puavo-touch-homedir':
      source => 'puppet:///modules/homedir_management/49puavo-touch-homedir';
  }

  ::puavo_conf::definition {
    'puavo-admin-cleanup-homedirs.json':
      source => 'puppet:///modules/homedir_management/puavo-admin-cleanup-homedirs.json';
  }

  ::puavo_conf::script {
    'cleanup_homedirs':
      require => Puavo_conf::Definition['puavo-admin-cleanup-homedirs.json'],
      source  => 'puppet:///modules/homedir_management/cleanup_homedirs';
  }
}
