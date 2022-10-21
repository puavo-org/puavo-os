class puavo_bash_completions {
  include ::packages
  file {
    '/usr/share/bash_completion/completions/'
      ensure => directory;

    '/usr/share/bash_completion/completions/puavo-make-install-disk':
      source => 'puppet:///modules/puavo_bash_completions/puavo-make-install-disk';

    '/usr/share/bash_completion/completions/puavo-bootserver-sync-images':
      source => 'puppet:///modules/puavo_bash_completions/puavo-bootserver-sync-images';
  }

  Package <| title == bash-completion |>
}
