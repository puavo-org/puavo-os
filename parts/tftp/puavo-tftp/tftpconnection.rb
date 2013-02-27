
require "eventmachine"

module PuavoTFTP

  # Abstract class for TFTP::Server and TFTPFileSender
  class Connection < EventMachine::Connection

    OPCODE_HANDLERS = {
      [Opcode::RRQ].pack("n")[1] => :handle_get,
      [Opcode::ACK].pack("n")[1] => :handle_ack,
      [Opcode::ERROR].pack("n")[1] => :handle_error
    }

    def receive_data(data)
      # debug "Server got data #{ data.inspect }"
      code = data[1]

      data = data.byteslice(2, data.size)
      handle_opcode(code, data)
    end

    def handle_opcode(code, data)
      if handler = OPCODE_HANDLERS[code]
        send(handler, data)
      else
        l "ERROR: Unknown opcode #{ code }: #{ data.inspect }"
      end
    end

    def handle_error(data)
      err_code, msg = data.unpack("nZ*")
      l "CLIENT ERROR: #{ ERROR_DESCRIPTIONS[err_code].inspect } msg: #{ msg }"
    end

    # Context aware log method
    def l(*args)
      args[0] = "#{ to_s } #{ args[0] }"
      log(*args)
    end

    if $tftp_debug
      # Context aware debug method
      def d(*args)
        args[0] = "#{ to_s } #{ args[0] }"
        debug(*args)
      end
    else
      def d(*args)
      end
    end

  end

end
