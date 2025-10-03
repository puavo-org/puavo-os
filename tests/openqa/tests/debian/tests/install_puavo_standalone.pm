use Mojo::Base 'basetest';
use testapi;

sub run {
  sleep 60;     # XXX should not be necessary!
  select_console 'ssh-serial';

  # XXX just some random tests
  sleep 30;
  assert_script_run('ls -l /');
  sleep 30;
}

sub test_flags {
  return { fatal => 1 };
}

1;
