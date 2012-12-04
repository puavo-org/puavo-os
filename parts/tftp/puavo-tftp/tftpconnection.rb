
require "eventmachine"

module PuavoTFTP

  # Abstract class for TFTP::Server and TFTPFileSender
  class Connection < EventMachine::Connection

    OPCODE_HANDLERS = {
      Opcode::RRQ => :handle_get,
      Opcode::ACK => :handle_ack,
      Opcode::ERROR => :handle_error
    }

    def receive_data(data)
      # debug "Server got data #{ data.inspect }"
      code = data.unpack("n").first
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
      code, err_code, msg = data.unpack("nnZ*")
      l "CLIENT ERROR: #{ ERROR_DESCRIPTIONS[err_code].inspect } msg: #{ msg }"
    end

    # Context aware log method
    def l(*args)
      args[0] = "#{ to_s } #{ args[0] }"
      log(*args)
    end

    # Context aware debug method
    def d(*args)
      args[0] = "#{ to_s } #{ args[0] }"
      debug(*args)
    end

  end

end
