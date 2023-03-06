class focal_libs {
  include ::trusty_libs::file_unpack

  $basedir = '/opt/focal/lib'
  $focal_mirror_base  = 'https://mirrors.kernel.org'

  define deb_unpack ($url, $srcpath) {
    $targetpath = "${::focal_libs::basedir}/${title}"

    exec {
      "/usr/local/lib/puavo-unpack-a-file-from-deb ${url} ${srcpath} ${targetpath}":
        creates => $targetpath,
        require => File['/usr/local/lib/puavo-unpack-a-file-from-deb'];
    }
  }

  ::focal_libs::deb_unpack {
    'x64_64-linux-gnu/libboost_chrono.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_chrono.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-chrono1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_date_time.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_date_time.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-date-time1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_filesystem.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-filesystem1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_program_options.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-program-options1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_regex.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_regex.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-regex1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_signals.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_signals.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-signals1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_system.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-system1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libboost_thread.so.1.67.0':
      srcpath => '/usr/lib/x86_64-linux-gnu/libboost_thread.so.1.67.0',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/b/boost1.67/libboost-thread1.67.0_1.67.0-17ubuntu8_amd64.deb";

    'x64_64-linux-gnu/libcrypto++.so.6':
      srcpath => '/usr/lib/x86_64-linux-gnu/libcrypto++.so.6',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/libc/libcrypto++/libcrypto++6_5.6.4-9build1_amd64.deb";

    'x64_64-linux-gnu/libicudata.so.66':
      srcpath => '/usr/lib/x86_64-linux-gnu/libicudata.so.66',
      url     => "http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb";

    'x64_64-linux-gnu/libicui18n.so.66':
      srcpath => '/usr/lib/x86_64-linux-gnu/libicui18n.so.66',
      url     => "http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb";

    'x64_64-linux-gnu/libicuio.so.66':
      srcpath => '/usr/lib/x86_64-linux-gnu/libicuio.so.66',
      url     => "http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb";

    'x64_64-linux-gnu/libicuuc.so.66':
      srcpath => '/usr/lib/x86_64-linux-gnu/libicuuc.so.66',
      url     => "http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu66_66.1-2ubuntu2.1_amd64.deb";

    'x64_64-linux-gnu/libjsoncpp.so.1':
      srcpath => '/usr/lib/x86_64-linux-gnu/libjsoncpp.so.1',
      url     => "${focal_mirror_base}/ubuntu/pool/main/libj/libjsoncpp/libjsoncpp1_1.7.4-3.1ubuntu2_amd64.deb";

    'x64_64-linux-gnu/liblog4cxx.so.10':
      srcpath => '/usr/lib/x86_64-linux-gnu/liblog4cxx.so.10',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/l/log4cxx/liblog4cxx10v5_0.10.0-15ubuntu2_amd64.deb";

    'x64_64-linux-gnu/libmysqlclient.so.21':
      srcpath => '/usr/lib/x86_64-linux-gnu/libmysqlclient.so.21',
      url     => "http://security.ubuntu.com/ubuntu/pool/main/m/mysql-8.0/libmysqlclient21_8.0.32-0ubuntu0.20.04.2_amd64.deb";

    'x64_64-linux-gnu/libxqilla.so.6':
      srcpath => '/usr/lib/x86_64-linux-gnu/libxqilla.so.6',
      url     => "${focal_mirror_base}/ubuntu/pool/universe/x/xqilla/libxqilla6v5_2.3.4-1build2_amd64.deb";
  }
}
