class chromium {
  include ::chromium::apps
  include ::dpkg
  include ::packages
  include ::puavo_conf

  dpkg::simpledivert {
    '/usr/bin/chromium':
      before => File['/usr/bin/chromium'];
  }

  # configuration for Puavo single sign-on
  chromium::install_policy { 'puavo-sso': ; }

  file {
    [ '/etc/chromium'
    , '/etc/chromium/policies'
    , '/etc/chromium/policies/managed'
    , '/etc/opt'
    , '/etc/opt/chrome'
    , '/etc/opt/chrome/policies'
    , '/etc/opt/chrome/policies/managed' ]:
      ensure => directory;

    '/etc/chromium/master_preferences':
      source => 'puppet:///modules/chromium/master_preferences';

    '/usr/bin/chromium':
      mode   => '0755',
      source => 'puppet:///modules/chromium/chromium';
  }

  define install_policy () {
    $policy_name = $title

    file {
      "/etc/chromium/policies/managed/${policy_name}.json":
	content => template("chromium/${policy_name}.json");

      "/etc/opt/chrome/policies/managed/${policy_name}.json":
	ensure  => link,
	require => File["/etc/chromium/policies/managed/${policy_name}.json"],
	target  => "/etc/chromium/policies/managed/${policy_name}.json";
    }
  }

  ::puavo_conf::definition {
    'puavo-www-chromium.json':
      source => 'puppet:///modules/chromium/puavo-www-chromium.json';
  }

  ::puavo_conf::script {
    'setup_chromium':
      require => ::Puavo_conf::Definition['puavo-www-chromium.json'],
      source  => 'puppet:///modules/chromium/setup_chromium';
  }

  Package <| title == chromium |>
}
