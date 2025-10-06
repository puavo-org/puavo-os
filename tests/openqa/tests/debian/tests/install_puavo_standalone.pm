use Mojo::Base 'basetest';
use testapi;

sub run {
  assert_screen('debian-login', timeout => 300);
  record_info('Debian', 'Login prompt reached');

  select_console 'ssh-serial';

  assert_script_run('sudo apt -y update');
  assert_script_run('sudo apt -y dist-upgrade');
}

sub test_flags {
  return { fatal => 1 };
}

1;
