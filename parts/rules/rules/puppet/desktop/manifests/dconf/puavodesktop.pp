class desktop::dconf::puavodesktop {
  include desktop::dconf

  define locale {
    $lang = $title

    file {
      "/etc/dconf/db/locale-${lang}.d":
        ensure => directory;

      "/etc/dconf/db/locale-${lang}.d/${lang}":
        content => template("desktop/dconf_by_locale/${lang}"),
        notify  => Exec['update dconf'];
    }
  }

  locale { [ 'ar', 'de', 'en', 'fi', 'fr', 'sv', ]: ; }

  file {
    [ '/etc/dconf/db/puavo-desktop.d'
    , '/etc/dconf/db/puavo-desktop.d/locks' ]:
      ensure => directory;

    '/etc/dconf/profile/user':
      content => template('desktop/dconf_profile_user');

    '/etc/environment':
      content => template('desktop/environment');
  }
}
