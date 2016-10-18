class bootserver_webdisk {
  file {
    '/usr/share/tomcat6/server/webapps/ba/webapp/WEB-INF/web.xml':
      content => template('bootserver_webdisk/web.xml');
  }
}
