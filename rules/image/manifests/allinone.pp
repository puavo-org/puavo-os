class image::allinone {
  include ::adm::users
  include ::image::bundle::basic
  include ::image::bundle::bootserver
  include ::image::bundle::desktop
  include ::plymouth

  stage {
    'init':
      before => Stage['pre-main'];

    'pre-main':
      before => Stage['main'];
  }

  class {
    'apt::default_repositories':
      stage => pre-main;
  }

  ::plymouth::install_theme     { 'kites': ; }
  ::plymouth::set_default_theme { 'kites': ; }

  Package <| tag == 'tag_kernel'
          or tag == 'tag_puavo'  |>

  Packages::Kernels::Kernel_package <| |>
}
