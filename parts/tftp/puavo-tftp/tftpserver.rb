
require "eventmachine"
require "socket"

require "puavo-tftp/constants"
require "puavo-tftp/tftpconnection"
require "puavo-tftp/tftpfilesender"
require "puavo-tftp/log"

# http://tools.ietf.org/html/rfc1350

module PuavoTFTP

  # TFTP server listening on a fixed port (default 69)
  class Server < Connection

    def initialize(root, hooks)
      @root = root
      @clients = {}
      @hooks = hooks
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
        l "Ignoring duplicate RRQ #{ ip }:#{ port } GET: #{ data.inspect }"
        return
      end

      # Create dedicated TFTP file sender server for this client
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0",
        0, # Listen on ephemeral port
        FileSender,
        ip,
        port,
        @root,
        @hooks
      )

      @clients[key] = sender
      sender.on_end { @clients.delete(key) }

      # Pass get handling to this one shot server
      sender.handle_get(data)
    end

  end

end
