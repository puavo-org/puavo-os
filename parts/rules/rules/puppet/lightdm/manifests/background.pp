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

#  XXX these images do not exist in Debian
#  @file {
#    "${backgrounds_dir}/Beach_by_Renato_Giordanelli.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-trusty'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Beach_by_Renato_Giordanelli.jpg';
#
#    "${backgrounds_dir}/Cairn_by_Sylvain_Naudin.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-quantal'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Cairn_by_Sylvain_Naudin.jpg';
#
#    "${backgrounds_dir}/Early_Morning_by_Robert_Katzki.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-quantal'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Early_Morning_by_Robert_Katzki.jpg';
#
#    "${backgrounds_dir}/Fleurs_de_Prunus_24_by_Jérôme_Boivin.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-raring'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Fleurs_de_Prunus_24_by_Jérôme_Boivin.jpg';
#
#    "${backgrounds_dir}/Ibanez_Infinity_by_Jaco_Kok.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-trusty'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Ibanez_Infinity_by_Jaco_Kok.jpg';
#
#    "${backgrounds_dir}/Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-raring'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Morning_Sun_on_Frost-Covered_Leaves_by_Gary_A_Stafford.jpg';
#
#    "${backgrounds_dir}/Nylon_Rainbow_by_Sam_Hewitt.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-saucy'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Nylon_Rainbow_by_Sam_Hewitt.jpg';
#
#    "${backgrounds_dir}/Pantano_de_Orellana_by_mgarciaiz.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-quantal'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Pantano_de_Orellana_by_mgarciaiz.jpg';
#
#    "${backgrounds_dir}/Partitura_by_Vincijun.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-trusty'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Partitura_by_Vincijun.jpg';
#
#    "${backgrounds_dir}/Speaker_Weave_by_Phil_Jackson.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-precise'],
#      tag     => [ 'tag_backgroundimages', 'tag_precise', 'tag_trusty', ],
#      target  => '../../Speaker_Weave_by_Phil_Jackson.jpg';
#
#    "${backgrounds_dir}/Tie_My_Boat_by_Ray_García.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-precise'],
#      tag     => [ 'tag_backgroundimages', 'tag_precise', 'tag_trusty', ],
#      target  => '../../Tie_My_Boat_by_Ray_García.jpg';
#
#    "${backgrounds_dir}/Vanishing_by_James_Wilson.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-quantal'],
#      tag     => [ 'tag_backgroundimages', 'tag_trusty', ],
#      target  => '../../Vanishing_by_James_Wilson.jpg';
#
#    "${backgrounds_dir}/Winter_Morning_by_Shannon_Lucas.jpg":
#      ensure  => link,
#      require => Package['ubuntu-wallpapers-precise'],
#      tag     => [ 'tag_backgroundimages', 'tag_precise', 'tag_trusty', ],
#      target  => '../../Winter_Morning_by_Shannon_Lucas.jpg';
#  }

  File    <| tag == 'tag_backgroundimages' and tag == "tag_$lsbdistcodename" |>
  Package <| tag == 'tag_backgroundimages' and tag == "tag_$lsbdistcodename" |>

  Package <| title == $image_package |>
}
