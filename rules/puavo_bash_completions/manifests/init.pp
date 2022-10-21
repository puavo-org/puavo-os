class puavo_bash_completions {
  include ::packages
  file {
    '/etc/bash_completion.d/'
      ensure => directory;

    '/etc/bash_completion.d/puavo-make-install-disk':
      source => 'puppet:///modules/puavo_bash_completions/puavo-make-install-disk';

    '/etc/bash_completion.d/puavo-bootserver-sync-images':
      source => 'puppet:///modules/puavo_bash_completions/puavo-bootserver-sync-images';
  }

  Package <| title == bash-completion |>
}
