class gnome_shell_extensions::puavodesktop {
  include ::gnome_shell_extensions
  include ::gnome_shell_extensions::ding
  include ::gnome_shell_extensions::screenkeyboardcontroller
  include ::themes

  # XXX Should use ::Gnome_shell_extensions::Add_extension <| |>
  # XXX but these need to upgraded and tested in Trixie one by one.
  # XXX These should work already:
  ::Gnome_shell_extensions::Add_extension <|
       title == 'appindicatorsupport@rgcjonas.gmail.com'
    or title == 'dash-to-panel@jderose9.github.com'
    or title == 'puavomenu@puavo.org'
    or title == 'quick-settings-tweaks@qwreey'
  |>
}
