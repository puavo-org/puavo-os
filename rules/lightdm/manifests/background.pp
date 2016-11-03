class lightdm::background {
  include ::desktop::dconf
  include ::lightdm
  include ::packages

  $image_package = 'debian-edu-artwork'
  $image_path    = '/usr/share/backgrounds/Golden_Bloom_by_Twinmama.jpg'

  $backgrounds_dir = '/usr/share/backgrounds/puavo-greeter/default'

  file {
    [ '/usr/share/backgrounds'
    , '/usr/share/backgrounds/puavo-greeter'
    , $backgrounds_dir ]:
      ensure => directory;

    '/etc/dconf/db/lightdm.d/lightdm_background_profile':
      content => template('lightdm/dconf_lightdm_background_profile'),
      notify  => Exec['update dconf'],
      require => Package[$image_package];
  }

  File    <| tag == 'tag_backgroundimages' and tag == "tag_$debianversioncodename" |>
  Package <| tag == 'tag_backgroundimages' and tag == "tag_$debianversioncodename" |>

  Package <| title == $image_package |>
}
