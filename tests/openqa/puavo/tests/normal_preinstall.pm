use Mojo::Base 'basetest';
use testapi;

sub run {
    select_console 'sut';

    # Start preinstall
    type_string('preinstall');
    send_key('ret', wait_screen_change => 1);
    sleep 2;

    send_key('ret', wait_screen_change => 1); # Select laptop as the host type
    sleep 30;

    send_key('ret', wait_screen_change => 1); # Select the first disk as installation target
    sleep 10;

    type_string('no'); # Do not install Windows to another partition
    send_key('ret', wait_screen_change => 1);
    sleep 5;

    # Confirm the installation
    type_string('yes');
    send_key('ret', wait_screen_change => 1);
    record_info('Puavo', 'Preinstalling...');

    # Press F2 every second until boot menu appear for maximum 5 minutes.
    # If the boot menu does not appear, this test fails.
    send_key_until_needlematch('boot-menu', 'f2', 300);
    record_info('UEFI', 'Boot menu reached, ready to boot into preinstallation');

    # We're done, in order to save the disk for other tests, we need to shutdown
    power('off');
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
