class gnome_shell_extensions::puavodesktop {
  include ::gnome_shell_extensions
  include ::gnome_shell_extensions::ding
  include ::gnome_shell_extensions::screenkeyboardcontroller

  ::Gnome_shell_extensions::Add_extension <| |>
}
