# TFTP server

### Dependencies

On Precise Pangolin

    sudo apt-get install ruby1.9.3 ruby-eventmachine libldap-ruby1.8

### Usage

    Usage: [sudo] ./server.rb [options]
        -r, --root PATH                  Serve files from directory.
        -u, --user USER                  Drop to user.
        -g, --group GROUP                Drop to group. Default nogroup
            --verbose                    Print more debugging stuff.
        -p, --port PORT                  Listen on port.


### Tests

Install minitest

    sudo apt-get install ruby-minitest

Run

    make run-tests
