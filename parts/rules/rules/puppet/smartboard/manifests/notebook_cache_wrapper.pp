class smartboard::notebook_cache_wrapper {
  include dpkg
  require packages

  dpkg::divert {
    '/opt/SMART Technologies/Notebook Software/bin/Notebook/.notebook_elf':
      dest => '/opt/SMART Technologies/Notebook Software/bin/Notebook/.notebook_elf.real';
  }

  file {
    '/opt/SMART Technologies/Notebook Software/bin/Notebook/.notebook_elf':
      content => template('smartboard/notebook-gallerycache-wrapper'),
      mode    => 755,
      require => Dpkg::Divert['/opt/SMART Technologies/Notebook Software/bin/Notebook/.notebook_elf'];
  }

  Package <| title == smart-notebook |>
}
