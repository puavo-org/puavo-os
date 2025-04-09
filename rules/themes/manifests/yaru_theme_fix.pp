class themes::yaru_theme_fix {
  include ::dpkg
  include ::packages

  define yaru_gnome_shell_path_fix () {
    $theme_subdir = "/usr/share/gnome-shell/theme/${title}"
    $gnome_shell_css_path = "${theme_subdir}/gnome-shell.css"

    ::dpkg::simpledivert {
      $gnome_shell_css_path:
        require => Package['yaru-theme-gnome-shell'];
    }

    exec {
      "fix ${gnome_shell_css_path}":
        command => "/usr/bin/sed 's|resource:///org/gnome/shell/theme|${theme_subdir}|g' '${gnome_shell_css_path}.distrib' > '${gnome_shell_css_path}.tmp' && /usr/bin/mv '${gnome_shell_css_path}.tmp' '${gnome_shell_css_path}'",
        creates => $gnome_shell_css_path,
        require => ::Dpkg::Simpledivert[$gnome_shell_css_path];
    }
  }

  ::themes::yaru_theme_fix::yaru_gnome_shell_path_fix {
    [ 'Yaru'
    , 'Yaru-bark'
    , 'Yaru-bark-dark'
    , 'Yaru-blue'
    , 'Yaru-blue-dark'
    , 'Yaru-dark'
    , 'Yaru-magenta'
    , 'Yaru-magenta-dark'
    , 'Yaru-olive'
    , 'Yaru-olive-dark'
    , 'Yaru-prussiangreen'
    , 'Yaru-prussiangreen-dark'
    , 'Yaru-purple'
    , 'Yaru-purple-dark'
    , 'Yaru-red'
    , 'Yaru-red-dark'
    , 'Yaru-sage'
    , 'Yaru-sage-dark'
    , 'Yaru-viridian'
    , 'Yaru-viridian-dark' ]:
      ;
  }

  Package <| title == "yaru-theme-gnome-shell" |>
}
