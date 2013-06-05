class smartboard::config {
  include puavo_external_files
  require packages

  file {
    '/etc/xdg/SMART Technologies.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Technologies.conf';

    '/etc/xdg/SMART Technologies/SMART Notebook.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Notebook.conf';
  }

  puavo_external_files::external_file {
    '/opt/SMART Technologies/common/data/.mp.1.1.dat':
      external_file_name => 'smartlicense';
  }

  Package <| tag == whiteboard-smartboard |>
}
