class wine::strip {
  exec {
    'strip wine binaries':
      command => 'find /usr/lib/x86_64-linux-gnu/wine /usr/lib/i386-linux-gnu/wine -type f -print0 | xargs -0 strip --strip-debug',
      # ntdll guards the whole tree.
      onlyif  => 'objdump -h /usr/lib/x86_64-linux-gnu/wine/x86_64-windows/ntdll.dll /usr/lib/i386-linux-gnu/wine/i386-windows/ntdll.dll | grep -q .debug_',
      path    => '/usr/bin',
      require => [ Package['wine32'], Package['wine64'], ];
  }
}
