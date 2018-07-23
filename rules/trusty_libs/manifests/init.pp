class trusty_libs {
  $trusty_mirror_base = 'https://mirrors.kernel.org'

  define deb_unpack ($url, $srcpath) {
    $targetpath = $title

    exec {
      "/usr/local/lib/puavo-unpack-a-file-from-deb ${url} ${srcpath} ${targetpath}":
        creates => $targetpath,
        require => File['/usr/local/lib/puavo-unpack-a-file-from-deb'];
    }
  }

  file {
    '/usr/local/lib/puavo-unpack-a-file-from-deb':
      mode   => '0755',
      source => 'puppet:///modules/trusty_libs/puavo-unpack-a-file-from-deb';
  }

  ::trusty_libs::deb_unpack {
    '/opt/trusty/lib/i386-linux-gnu/libgiomm-2.4.so.1':
      srcpath => '/usr/lib/i386-linux-gnu/libgiomm-2.4.so.1.3.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_i386.deb";

    '/opt/trusty/lib/i386-linux-gnu/libglibmm-2.4.so.1':
      srcpath => '/usr/lib/i386-linux-gnu/libglibmm-2.4.so.1.3.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_i386.deb";

    '/opt/trusty/lib/i386-linux-gnu/libgdkmm-2.4.so.1':
      srcpath => '/usr/lib/i386-linux-gnu/libgdkmm-2.4.so.1.1.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_i386.deb";

    '/opt/trusty/lib/i386-linux-gnu/libgtkmm-2.4.so.1':
      srcpath => '/usr/lib/i386-linux-gnu/libgtkmm-2.4.so.1.1.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_i386.deb";

    '/opt/trusty/lib/x64_64-linux-gnu/libcairomm-1.0.so.1':
      srcpath => '/usr/lib/x86_64-linux-gnu/libcairomm-1.0.so.1.4.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/c/cairomm/libcairomm-1.0-1_1.10.0-1ubuntu3_amd64.deb";

    '/opt/trusty/lib/x64_64-linux-gnu/libglibmm-2.4.so.1':
      srcpath => '/usr/lib/x86_64-linux-gnu/libglibmm-2.4.so.1.3.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_amd64.deb";

    '/opt/trusty/lib/x64_64-linux-gnu/libgtkmm-2.4.so.1':
      srcpath => '/usr/lib/x86_64-linux-gnu/libgtkmm-2.4.so.1.1.0',
      url     => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_amd64.deb";
  }
}
