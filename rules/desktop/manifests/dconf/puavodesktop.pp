class desktop::dconf::puavodesktop {
  include ::dconf

  define locale {
    $lang = $title
    $lang_laptop = "${lang}-laptop"

    file {
      [ "/etc/dconf/db/locale-${lang}.d"
      , "/etc/dconf/db/locale-${lang_laptop}.d" ]:
        ensure => directory;
    }

    ::dconf::configfile {
      "dconf ${lang}":
        content => template("desktop/dconf_by_locale/${lang}"),
        dbname  => "locale-${lang}",
        subpath => "${lang}";

      "dconf ${lang_laptop}":
        content => template("desktop/dconf_by_locale/${lang_laptop}"),
        dbname  => "locale-${lang_laptop}",
        subpath => "${lang_laptop}";
    }
  }

  ::desktop::dconf::puavodesktop::locale {
    [ 'de', 'en', 'fi', 'fr', 'sv', 'uk', ]:
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
