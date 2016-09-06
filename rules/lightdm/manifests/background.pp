class lightdm::background {
  include desktop::dconf,
	  lightdm,
          packages

  $image_path = $lsbdistcodename ? {
    'precise' => '/usr/share/backgrounds/Golden_Bloom_by_Twinmama.jpg',
    default   => '/usr/share/backgrounds/Nylon_Rainbow_by_Sam_Hewitt.jpg',
  }

  $image_package = $lsbdistcodename ? {
    default => 'debian-edu-artwork',
  }

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

  File    <| tag == 'tag_backgroundimages' and tag == "tag_$lsbdistcodename" |>
  Package <| tag == 'tag_backgroundimages' and tag == "tag_$lsbdistcodename" |>

  Package <| title == $image_package |>
}
