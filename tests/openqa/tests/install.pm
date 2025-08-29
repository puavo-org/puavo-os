use Mojo::Base 'basetest';
use testapi;

sub run {
    select_console 'sut';

    # We assume we're currently in the primary console and US layout is enabled.

    # Open a new tmux window to get a fresh shell
    send_key('ctrl-b');
    send_key('c');
    sleep 2;

    # TODO: This is a temporary hack around registration
    type_string("echo 'echo laptop > /etc/puavo/hosttype' > /usr/sbin/puavo-register");
    send_key('ret', wait_screen_change => 1);
    sleep 2;
    type_string("echo puavo.qa.fake > /etc/puavo/domain");
    send_key('ret', wait_screen_change => 1);
    sleep 2;

    # Return back to the primary console
    send_key('ctrl-b');
    send_key('0');
    sleep 2;

    # Start install
    type_string('install');
    send_key('ret', wait_screen_change => 1);
    sleep 15;

    # Open a new tmux window to get a fresh shell
    send_key('ctrl-b');
    send_key('c');
    sleep 2;

    type_string('reboot');
    send_key('ret', wait_screen_change => 1);

    assert_screen('login-screen', timeout => 300);
    record_info('Puavo', 'Login screen reached');
}

sub test_flags {
    return { fatal => 1 };
}

1;

