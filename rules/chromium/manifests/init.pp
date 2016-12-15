class chromium {
  include ::chromium::office365_tweaks
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/usr/bin/chromium':
      before => File['/usr/bin/chromium'];
  }

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

  Package <| title == chromium |>
}
