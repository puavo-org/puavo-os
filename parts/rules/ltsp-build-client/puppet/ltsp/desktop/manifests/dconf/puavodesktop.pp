class desktop::dconf::puavodesktop {
  include desktop::dconf

  define locale {
    $lang = $title

    file {
      "/etc/dconf/profile/user-${lang}":
        content => template("desktop/dconf_profile_user-${lang}");
    }
  }

  locale { [ 'en', 'fi', 'sv', ]: ; }

  file {
    [ '/etc/dconf/db/puavodesktop.d'
    , '/etc/dconf/db/puavodesktop.d/locks' ]:
      ensure => directory;

    '/etc/dconf/profile/user':
      content => template('desktop/dconf_profile_user-en');

    '/etc/environment':
      content => template('desktop/environment');
  }
}
