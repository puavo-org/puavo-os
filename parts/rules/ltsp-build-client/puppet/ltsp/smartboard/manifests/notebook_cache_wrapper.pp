class smartboard::notebook_cache_wrapper {
  include dpkg
  require packages

  dpkg::divert {
    '/opt/SMART Technologies/Notebook Software/bin/Notebook/notebook':
      dest => '/opt/SMART Technologies/Notebook Software/bin/Notebook/notebook.real';
  }

  file {
    '/opt/SMART Technologies/Notebook Software/bin/Notebook/notebook':
      content => template('smartboard/notebook-gallerycache-wrapper'),
      mode    => 755,
      require => Dpkg::Divert['/opt/SMART Technologies/Notebook Software/bin/Notebook/notebook'];
  }

  Package <| title == smart-notebook |>
}
