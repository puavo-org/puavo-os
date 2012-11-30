
require "eventmachine"
require "socket"

require "./lib/constants"
require "./lib/tftpconnection"
require "./lib/tftpfilesender"
require "./lib/log"

# http://tools.ietf.org/html/rfc1350

module TFTP

  # TFTP server listening on a fixed port (default 69)
  class Server < Connection

    def initialize(filereader)
      @filereader = filereader
    end

    def to_s
      "<Server fixed>"
    end

    def handle_get(data)
      port, ip = Socket.unpack_sockaddr_in(get_peername)

      # Create dedicated TFTP file sender server for this client
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0",
        0, # Listen on ephemeral port
        FileSender,
        ip,
        port,
        @filereader
      )

      # Pass get handling to this one shot server
      sender.handle_get(data)
    end

  end

end
