
require "eventmachine"
require "socket"

require "./lib/tftpserver"
require "./lib/cachedfilereader"
require "./lib/log"

PORT = 69
ROOT = "./test/tftpboot/"

EventMachine::run do
  l = EventMachine::open_datagram_socket("0.0.0.0", PORT, TFTP::Server, ROOT)
  log "TFTP server now listening on port #{ PORT }, #{ l.inspect }"
end

