class apt::repositories {
  include apt

  define setup ($localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    file {
      '/etc/apt/preferences.d/00-backports.pref':
	content => template('apt/00-backports.pref'),
	notify  => Exec['apt update'];

      '/etc/apt/sources.list':
	content => template('apt/sources.list'),
	notify  => Exec['apt update'];
    }
  }
}
