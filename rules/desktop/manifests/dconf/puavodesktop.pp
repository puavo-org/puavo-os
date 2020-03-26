class desktop::dconf::puavodesktop {
  include ::desktop::dconf

  define locale {
    $lang = $title
    $lang_laptop = "${lang}-laptop"

    file {
      [ "/etc/dconf/db/locale-${lang}.d"
      , "/etc/dconf/db/locale-${lang_laptop}.d" ]:
        ensure => directory;

      "/etc/dconf/db/locale-${lang}.d/${lang}":
        content => template("desktop/dconf_by_locale/${lang}"),
        notify  => Exec['update dconf'];

      "/etc/dconf/db/locale-${lang_laptop}.d/${lang_laptop}":
        content => template("desktop/dconf_by_locale/${lang_laptop}"),
        notify  => Exec['update dconf'];
    }
  }

  ::desktop::dconf::puavodesktop::locale {
    [ 'ar', 'de', 'en', 'fi', 'fr', 'id', 'sv', ]:
      ;
  }

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
