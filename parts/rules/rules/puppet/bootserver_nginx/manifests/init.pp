class bootserver_nginx {
  define enable {
    $service_name = $title

    file {
      "/etc/nginx/sites-enabled/${service_name}":
	ensure => link,
	notify => Service['nginx'],
	target => "/etc/nginx/sites-available/${service_name}";
    }
  }

  service {
    'nginx':
      ensure => running;
  }
}
