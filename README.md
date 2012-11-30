# puavo-ltsp

## TFTP server

### Dependencies

On Precise Pangolin

    sudo apt-get install ruby1.9.3 ruby-eventmachine

### Usage

    Usage: [sudo] ./server.rb [options]
        -r, --root PATH                  Serve files from directory
            --verbose                    Print more debugging stuff
        -p, --port PORT                  Listen on port


### Tests

Install minitest

    sudo apt-get install ruby-minitest

Run

    make run-tests
