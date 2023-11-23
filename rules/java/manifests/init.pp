class java {
  exec {
    'set puavo-java as java':
      command => '/usr/bin/update-alternatives --install /usr/bin/java java /usr/local/bin/puavo-java 30001 && /usr/bin/update-alternatives --set java /usr/local/bin/puavo-java',
      require => File['/usr/local/bin/puavo-java'],
      unless  => "/usr/bin/update-alternatives --query java | /bin/grep -qx 'Value: /usr/local/bin/puavo-java'";
  }

  file {
    '/usr/local/bin/puavo-java':
      mode   => '0755',
      source => 'puppet:///modules/java/puavo-java';
  }
}
