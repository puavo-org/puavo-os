class chromium::apps {
  define app ($app_id) {
    $app_name = $title

    file {
      "/opt/puavo-chromium-apps/${app_name}":
        ensure => directory;

      "/opt/puavo-chromium-apps/${app_name}/app_id":
        content => "${app_id}\n";

      "/opt/puavo-chromium-apps/${app_name}/logo.png":
        source => "puppet:///modules/chromium/apps/${app_name}/logo.png";

      "/opt/puavo-chromium-apps/${app_name}/puavo-chromium-app.tar.gz":
        source => "puppet:///modules/chromium/apps/${app_name}/puavo-chromium-app.tar.gz";
    }
  }

  file {
    '/opt/puavo-chromium-apps':
      ensure => directory;

    '/usr/local/bin/puavo-chromium-app':
      mode   => '0755',
      source => 'puppet:///modules/chromium/puavo-chromium-app';
  }

  ::chromium::apps::app {
    'novo_desktop_streamer':
       app_id => 'hlccdhlihfddoncokklgmhmijmpdmenb';

    'sphere_lite':
       app_id => 'bhmibpbadaengbikmoglphhlhioajdjn';
  }
}
