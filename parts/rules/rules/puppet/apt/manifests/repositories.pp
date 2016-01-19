class apt::repositories {
  include apt

  define setup ($mirror,
                $mirror_path='',
                $partnermirror,
                $partnermirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    file {
      # The default proposed updates (with "Package: *") should be at the
      # beginning of the prefs list, so that other settings may override it
      # (so we can selectively install only *some* proposed updates, and by
      # default not install any).
      '/etc/apt/preferences.d/00_proposed_updates.pref':
	content => template('apt/apt_preferences_d_00_proposed_updates.pref');

      '/etc/apt/sources.list':
	content => template('apt/sources.list'),
	notify  => Exec['apt update'];
    }

    @apt::repository {
      'partner':
        aptline => "http://${partnermirror}${partnermirror_path}/ubuntu $lsbdistcodename partner";

      'proposed':
        aptline => "http://${mirror}${mirror_path}/ubuntu ${lsbdistcodename}-proposed main restricted universe multiverse";
    }
  }
}
