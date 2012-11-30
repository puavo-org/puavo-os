
require "eventmachine"
require "socket"

require "./lib/constants"
require "./lib/tftpconnection"
require "./lib/tftpfilesender"
require "./lib/cachedfilereader"
require "./lib/log"

# http://tools.ietf.org/html/rfc1350

module TFTP

  # TFTP server listening on a fixed port (default 69)
  class Server < TFTPConnection

    def initialize(root)
      @filereader = CachedFileReader.new(root)
    end

    def to_s
      "<Server fixed>"
    end

    def handle_get(data)

      port, ip = Socket.unpack_sockaddr_in(get_peername)

      # Create dedicated TFTP file sender server for this client on a ephemeral
      # (random) port.
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0", 0, TFTPFileSender, ip, port, @filereader
      )

      sender.handle_get(data)
    end

  end

end
