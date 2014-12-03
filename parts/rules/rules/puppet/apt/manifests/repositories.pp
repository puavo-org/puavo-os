class apt::repositories {
  include apt

  define setup ($mirror, $partnermirror, $securitymirror) {
    file {
      '/etc/apt/sources.list':
	content => template('apt/sources.list'),
	notify  => Exec['apt update'];
    }

    @apt::repository {
      'partner':
        aptline => "http://${partnermirror}/ubuntu $lsbdistcodename partner";
    }
  }
}
