class image::allinone {
  include ::adm::users
  include ::image::bundle::basic
  include ::image::bundle::bootserver
  include ::image::bundle::desktop

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

  Package <| tag == 'tag_kernel'
          or tag == 'tag_puavo'  |>
}
