class image::bootserver {
  include ::adm::users
  include ::image::bundle::basic

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

  Package <| tag == 'tag_debian'
          or tag == 'tag_debian_backports'
          or tag == 'tag_kernel'
          or tag == 'tag_puavo' |>
}
