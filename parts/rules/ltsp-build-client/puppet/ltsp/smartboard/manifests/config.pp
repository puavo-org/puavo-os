class smartboard::config {
  require packages,
          puavo_external_files

  file {
    '/etc/puavo-external-files-actions.d/smartboard':
      content => template('smartboard/puavo-external-files-actions.d/smartboard'),
      mode    => 755;

    '/etc/xdg/SMART Technologies.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Technologies.conf';

    '/etc/xdg/SMART Technologies/SMART Notebook.conf':
      mode   => 644,
      source => 'puppet:///modules/smartboard/SMART_Notebook.conf';
  }

  puavo_external_files::external_file {
    '/opt/SMART Technologies/common/data/.mp.1.1.dat':
      external_file_name => 'smartboard_license';
  }

  Package <| tag == whiteboard-smartboard |>
}
