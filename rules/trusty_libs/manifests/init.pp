class trusty_libs {
  include ::packages

  $basedir = '/opt/trusty/lib'
  $trusty_mirror_base  = 'https://mirrors.kernel.org'

  define deb_unpack ($url, $sha384sum, $dest_subdir, $linkname='') {
    $srcpath    = $title
    $destdir    = "${::trusty_libs::basedir}/${dest_subdir}"
    $targetname = inline_template("<%= File.basename(scope.lookupvar('srcpath')) %>")
    $targetpath = "${destdir}/${targetname}"

    exec {
      "unpack ${srcpath}":
        command => "/usr/lib/puavo-pkg/unpack-a-file-from-deb ${url} ${sha384sum} ${destdir} ${srcpath}",
        creates => $targetpath,
        require => Package['puavo-pkg'];
    }

    if $linkname != '' {
      file {
        "${destdir}/${linkname}":
          ensure  => link,
          require => Exec["unpack ${srcpath}"],
          target  => $targetname;
      }
    }
  }

  ::trusty_libs::deb_unpack {
    '/usr/lib/i386-linux-gnu/libgiomm-2.4.so.1.3.0':
      dest_subdir => 'i386-linux-gnu',
      linkname    => 'libgiomm-2.4.so.1',
      sha384sum   => 'ac8318798a7c965703b55b61f4ae538ff5a69d96ac33cbe593f1d35076233a829ae1ba950ee9e59a08fce3ca5a099530',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_i386.deb";

    '/usr/lib/i386-linux-gnu/libglibmm-2.4.so.1':
      dest_subdir => 'i386-linux-gnu',
      sha384sum   => 'ac8318798a7c965703b55b61f4ae538ff5a69d96ac33cbe593f1d35076233a829ae1ba950ee9e59a08fce3ca5a099530',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_i386.deb";

    '/usr/lib/i386-linux-gnu/libgdkmm-2.4.so.1':
      dest_subdir => 'i386-linux-gnu',
      sha384sum   => 'adaaa3ad4d78579fd38193fdf797cb817f181563c1e6e8437cd2f6a13f35c646f6a787bba79c0d25b6f201aba7ae457b',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_i386.deb";

    '/usr/lib/i386-linux-gnu/libgtkmm-2.4.so.1.1.0':
      dest_subdir => 'i386-linux-gnu',
      linkname    => 'libgtkmm-2.4.so.1',
      sha384sum   => 'adaaa3ad4d78579fd38193fdf797cb817f181563c1e6e8437cd2f6a13f35c646f6a787bba79c0d25b6f201aba7ae457b',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_i386.deb";

    '/lib/i386-linux-gnu/libpng12.so.0.54.0':
      dest_subdir => 'i386-linux-gnu',
      linkname    => 'libpng12.so.0',
      sha384sum   => '1e214ec9447bc6fa97e2eefa0e40c3939417b316b9e9a3d79fcb4b8cd1cf0ae98d4afb8d6ba41ce028723af3427f9c81',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1.1_i386.deb";

    '/usr/lib/x86_64-linux-gnu/libatkmm-1.6.so.1.1.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libatkmm-1.6.so.1',
      sha384sum   => '7fba086000aaed51d1fe4fb89253dd0bfeb4be0b94b312aca0d1807048e29988e327c082082e16122d052dd1290631c9',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/a/atkmm1.6/libatkmm-1.6-1_2.22.7-2ubuntu1_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libcairomm-1.0.so.1.4.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libcairomm-1.0.so.1',
      sha384sum   => 'a3fc331d286eef4b86285a4d85a22336970e551f6127daa96d9bb676939ae09450f62125f69fb0b01f7e41d5bcd5058e',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/c/cairomm/libcairomm-1.0-1_1.10.0-1ubuntu3_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libgdkmm-2.4.so.1.1.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libgdkmm-2.4.so.1',
      sha384sum   => 'f3959cf128db908cdfdd4bee95ffdac604f24baafafc2b6776b86f38fb2254b2c4120fefe4d8a43ffd41b697d9dffffa',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libgiomm-2.4.so.1.3.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libgiomm-2.4.so.1',
      sha384sum   => '644fb099f673ad8aca8619823bbab0ce76caaeac3fea70bb098d4acde839f6934a1f1504959795866e43acd86c24347a',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libglibmm-2.4.so.1.3.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libglibmm-2.4.so.1',
      sha384sum   => '644fb099f673ad8aca8619823bbab0ce76caaeac3fea70bb098d4acde839f6934a1f1504959795866e43acd86c24347a',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/glibmm2.4/libglibmm-2.4-1c2a_2.39.93-0ubuntu1_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libgtkmm-2.4.so.1.1.0':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libgtkmm-2.4.so.1',
      sha384sum   => 'f3959cf128db908cdfdd4bee95ffdac604f24baafafc2b6776b86f38fb2254b2c4120fefe4d8a43ffd41b697d9dffffa',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/g/gtkmm2.4/libgtkmm-2.4-1c2a_2.24.4-1ubuntu1_amd64.deb";

    '/usr/lib/x86_64-linux-gnu/libpangomm-1.4.so.1.0.30':
      dest_subdir => 'x86_64-linux-gnu',
      linkname    => 'libpangomm-1.4.so.1',
      sha384sum   => 'c4bea9aa637dd5702075723b4e58782687967f37f81ea5540646f3768733ae7ea1834860c324655a82c64a32c0ce1aab',
      url         => "${trusty_mirror_base}/ubuntu/pool/main/p/pangomm/libpangomm-1.4-1_2.34.0-1ubuntu1_amd64.deb";
  }

  Package <| title == "puavo-pkg" |>
}
