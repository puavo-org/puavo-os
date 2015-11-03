class graphics_stack_hacks::edgers_mesa_dri {
  include graphics_stack_hacks,
          packages

  graphics_stack_hacks::download_alternative_deb {
    'libdrm-amdgpu1':
      file    => 'libdrm-amdgpu1_2.4.65+git20151026.c745e541-0ubuntu0ricotz~trusty_i386.deb',
      urlbase => 'http://archive.opinsys.fi/xorg-edgers/pool/trusty/main/libd/libdrm';

    'libgl1-mesa-dri':
      file    => 'libgl1-mesa-dri_11.0.4~git20151026+11.0.ec14e6f8-0ubuntu0ricotz~trusty_i386.deb',
      urlbase => 'http://archive.opinsys.fi/xorg-edgers/pool/trusty/main/m/mesa';

    'libllvm3.6':
      file    => 'llvm-3.6_3.6~+rc2-2ubuntu1~xedgers14.04.1_i386.deb',
      urlbase => 'http://archive.opinsys.fi/xorg-edgers/pool/trusty/main/l/llvm-toolchain-3.6';
  }

  file {
    '/usr/share/puavo-ltsp/init-puavo.d/93-alternate-edgers-mesa-dri':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/graphics_stack_hacks/93-alternate-edgers-mesa-dri';
  }

  Package <| title == puavo-ltsp-client |>
}
