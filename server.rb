

require "./lib/tftpserver"

PORT = 69
ROOT = "./test/tftpboot/"

EventMachine::run do
  EventMachine::open_datagram_socket("0.0.0.0", PORT, TFTP::Server, ROOT)
end
