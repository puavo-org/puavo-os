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

  assert_screen('grub-installation-done', timeout => 300);
  record_info('Puavo', 'Grub installation done.');

  assert_screen('install-success', timeout => 300);
  record_info('Puavo', 'Installation successful.');

  assert_screen('rebooting-after-install', timeout => 300);
  record_info('Puavo', 'Rebooting after installation.');

  # In order to save the disk for other tests, we need to shutdown.
  power('acpi');
  assert_shutdown();
}

sub test_flags {
  return { fatal => 1, milestone => 1 };
}

1;
