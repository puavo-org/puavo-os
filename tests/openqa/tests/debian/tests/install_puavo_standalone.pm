use Mojo::Base 'basetest';
use testapi;

sub run {
  select_console 'sut';
  assert_screen('debian-boot-ready', timeout => 3000);
}

sub test_flags {
  return { fatal => 1 };
}

1;
