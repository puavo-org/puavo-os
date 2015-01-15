class apt::repositories {
  include apt

  define setup ($mirror,
                $mirror_path='',
                $partnermirror,
                $partnermirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    file {
      '/etc/apt/sources.list':
	content => template('apt/sources.list'),
	notify  => Exec['apt update'];
    }

    @apt::repository {
      'partner':
        aptline => "http://${partnermirror}${partnermirror_path}/ubuntu $lsbdistcodename partner";
    }
  }
}
