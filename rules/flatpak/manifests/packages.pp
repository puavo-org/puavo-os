class flatpak::packages {
  include ::flatpak

  @::flatpak::install {
    'org.shotcut.Shotcut': ;
  }
}
