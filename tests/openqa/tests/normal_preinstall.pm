use Mojo::Base 'basetest';
use testapi;

sub run {
  select_console 'sut';

  # Start preinstall.
  type_string('preinstall');
  send_key('ret', wait_screen_change => 1);
  send_key('ret', wait_screen_change => 1); # select laptop as the host type
  send_key('ret', wait_screen_change => 1); # select the first disk as target

  type_string('no'); # do not install Windows to another partition
  send_key('ret', wait_screen_change => 1);

  # Confirm the installation.
  type_string('yes');
  send_key('ret', wait_screen_change => 1);
  record_info('Puavo', 'Preinstalling...');

  assert_screen('preinstall-done', timeout => 300);
  record_info('Puavo', 'Preinstallation done');

  # System should now reboot itself.  Press F2 every second until BIOS menu
  # appears for maximum three minutes.  If the boot menu does not appear,
  # this test fails.
  send_key_until_needlematch('bios', 'f2', 180);
  record_info('UEFI', 'BIOS setup reached');

  # Installation done.  In order to save the disk for other tests, we need
  # to shutdown.
  power('off');
}

sub test_flags {
  return { fatal => 1, milestone => 1 };
}

1;
