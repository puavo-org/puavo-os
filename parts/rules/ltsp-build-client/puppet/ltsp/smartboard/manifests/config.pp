class smartboard::config {
  require packages

  file {
    '/etc/xdg/SMART Technologies.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Technologies.conf';

    '/etc/xdg/SMART Technologies/SMART Notebook.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Notebook.conf';
  }

  Package <| tag == whiteboard-smartboard |>
}
