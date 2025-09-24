use Mojo::Base 'basetest';
use PuavoOS;
use testapi;

sub run {
  select_console 'sut';
  PuavoOS::darkdm_install('crypt-preinstall');
}

sub test_flags {
  return { fatal => 1, milestone => 1 };
}

1;
