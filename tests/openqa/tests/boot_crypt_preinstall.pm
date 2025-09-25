use Mojo::Base 'basetest';
use testapi;

sub run {
  select_console 'sut';

  # Wait until the disk installer UI shows up (DarkDM)
  assert_screen('darkdm-preinstalled', timeout => 300);
  record_info('Puavo', 'DarkDM reached');
  assert_screen('darkdm-preinstalled-ready', timeout => 300);
  record_info('Puavo', 'DarkDM ready');

  # Switch keyboard layout to US
  type_string('kbd us');
  send_key('ret', wait_screen_change => 1);

  # Open a new tmux window to get a fresh shell
  send_key('ctrl-b');
  send_key('c', wait_screen_change => 1);

  # Verify host type indicates a preinstalled system
  assert_script_run('grep -q preinstalled /etc/puavo/hosttype',
                    timeout => 30);
  record_info('Puavo', 'Host type is preinstalled');

  assert_script_run(q{dmesg | grep 'Secure boot enabled'}, timeout => 30);
  record_info('Puavo', 'Secure Boot is enabled');

  assert_script_run(q{mount -l | grep -q '/dev/mapper/root on /images'},
                    timeout => 30);
  record_info('Puavo', 'Disk is encrypted');

  # Return back to the primary console
  type_string('exit 0');
  send_key('ret', wait_screen_change => 1);
}

sub test_flags {
  return { fatal => 1 };
}

1;
