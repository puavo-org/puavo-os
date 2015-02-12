class bootserver_nginx {
  define enable {
    $service_name = $title

    file {
      "/etc/nginx/sites-enabled/${service_name}":
	ensure => link,
	notify => Exec['reload nginx'],
	target => "/etc/nginx/sites-available/${service_name}";
    }
  }

  exec {
    'reload nginx':
      command     => '/usr/sbin/service nginx reload',
      refreshonly => true,
      require     => Service['nginx'];
  }

  service {
    'nginx':
      ensure => running;
  }
}
