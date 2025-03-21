class gnome_shell_extensions::exammode {
  include ::gnome_shell_extensions

  ::Gnome_shell_extensions::Add_extension <|
       title == 'appindicatorsupport@rgcjonas.gmail.com'
    or title == 'dash-to-panel@jderose9.github.com'
    or title == 'quick-settings-tweaks@qwreey'
  |>
}
