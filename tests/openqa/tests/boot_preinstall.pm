use Mojo::Base 'basetest';
use testapi;

sub run {
  select_console 'sut';

  while (1) {
    record_info('screenshot', 'Just saving a screenshot');
    save_screenshot();
    sleep 1;
  }

  # wait until the disk installer ui shows up (darkdm).
  assert_screen('darkdm-preinstalled', timeout => 300);
  record_info('puavo', 'darkdm reached');
  assert_screen('darkdm-diskinstaller-ready', timeout => 300);
  record_info('puavo', 'darkdm ready');

  # Switch keyboard layout to US.
  type_string('kbd us');
  send_key('ret', wait_screen_change => 1);

  # Open a new tmux window to get a fresh shell.
  send_key('ctrl-b');
  send_key('c', wait_screen_change => 1);

  # Verify host type indicates a preinstalled system.
  assert_script_run('grep -qx preinstalled /etc/puavo/hosttype',
                    timeout => 30);
  record_info('Puavo', 'Host type is preinstalled');

  assert_script_run(q{dmesg | grep -q 'Secure boot enabled'}, timeout => 30);
  record_info('Puavo', 'Secure Boot is enabled');

  # Return back to the primary console
  type_string('exit 0');
  send_key('ret', wait_screen_change => 1);
}

sub test_flags {
  return { fatal => 1 };
}

1;
