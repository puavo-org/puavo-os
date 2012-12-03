
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
      @clients = {}
    end

    def to_s
      "<Server fixed>"
    end

    def handle_get(data)
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      key = "#{ ip }:#{ port }:#{ data }"

      # If we are slow the client might timeout and resend the GET packet. We
      # must just ignore it and continue.
      if @clients[key]
        d "Ignoring duplicate RRQ #{ ip }:#{ port } GET: #{ data.inspect }"
        return
      end

      # Create dedicated TFTP file sender server for this client
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0",
        0, # Listen on ephemeral port
        FileSender,
        ip,
        port,
        @filereader
      )

      @clients[key] = sender

      # Pass get handling to this one shot server
      sender.handle_get(data)
      sender.on_end { @clients.delete(key) }
    end

  end

end
