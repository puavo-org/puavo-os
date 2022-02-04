class tmux {
  include ::packages
  include ::puavo_conf
  include ::puavo_pkg

  ::puavo_conf::script {
    'setup_tmux':
      require => Puavo_pkg::Install['tmux-plugins-battery'],
      source  => 'puppet:///modules/tmux/setup_tmux';
  }

  Package <| title == tmux |>
  Puavo_pkg::Install <| title == "tmux-plugins-battery" |>
}
