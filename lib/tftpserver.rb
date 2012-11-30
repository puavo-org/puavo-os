
require "eventmachine"
require "socket"

require "./lib/cachedfilereader"
require "./lib/log"

# http://tools.ietf.org/html/rfc1350

module TFTP

  # http://tools.ietf.org/html/rfc1350#section-5
  module Opcode
    RRQ = 1
    WRQ = 2
    DATA = 3
    ACK = 4
    ERROR = 5
    OACK = 6
  end

  # http://tools.ietf.org/html/rfc1350#page-10
  module ErrorCode
    NOT_DEFINED = 0
    NOT_FOUND = 1
    ACCESS_VIOLATION = 2
    DISK_FULL = 3
    ILLEGAL_TFTP_OPERATION = 4
    UNKNOWN_TRANSFER_ID = 5
    FILE_ALREADY_EXISTS = 6
    NO_SUCH_USER = 7
  end

  ERROR_DESCRIPTIONS = {
    ErrorCode::NOT_FOUND => "File not found.",
    ErrorCode::ACCESS_VIOLATION => "Access violation.",
    ErrorCode::DISK_FULL => "Disk full or allocation exceeded.",
    ErrorCode::ILLEGAL_TFTP_OPERATION => "Illegal TFTP operation.",
    ErrorCode::UNKNOWN_TRANSFER_ID => "Unknown transfer ID.",
    ErrorCode::FILE_ALREADY_EXISTS => "File already exists.",
    ErrorCode::NO_SUCH_USER => "No such user."
  }

  OPCODE_HANDLERS = {
    Opcode::RRQ => :handle_get,
    Opcode::ACK => :handle_ack,
    Opcode::ERROR => :handle_error
  }

  class TFTPConnection < EventMachine::Connection

    def receive_data(data)
      # debug "Server got data #{ data.inspect }"
      code = data.unpack("n").first
      handle_opcode(code, data)
    end

    def handle_opcode(code, data)
      if handler = OPCODE_HANDLERS[code]
        send(handler, data)
      else
        log "Unknown opcode #{ code }: #{ data.inspect }"
      end
    end

    def handle_error(data)
      code, err_code, msg = data.unpack("nnZ*")
      l "CLIENT ERROR: #{ ERROR_DESCRIPTIONS[err_code].inspect } msg: #{ msg }"
    end

    def l(*args)
      args[0] = "#{ to_s } #{ args[0] }"
      log(*args)
    end

    def d(*args)
      args[0] = "#{ to_s } #{ args[0] }"
      debug(*args)
    end

  end

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
      # (random) port
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0", 0, FileSender, ip, port, @filereader
      )

      sender.handle_get(data)
    end

  end

  #TODO http://eventmachine.rubyforge.org/EventMachine/Connection.html#close_connection-instance_method

  # One shot TFTP file sender server listening on ephemeral port
  class FileSender < TFTPConnection

    BLOCK_SIZE = 512
    TIMEOUT = 1
    RETRY_COUNT = 5

    # @param {String} client ip
    # @param {Fixnum} client port
    def initialize(ip, port, filereader)
      @filereader = filereader
      @ip = ip
      @port = port

      @block_num = 0
      @data = nil
      @name = nil
      @current = nil
      @current_block_size = nil
    end

    def to_s
      "<FileSender #{ @ip }:#{ @port } #{ @name }>"
    end


    # @param {String} data octet string
    def handle_get(data)
      _, name, mode, *opts = data.unpack("nZ*Z*Z*Z*Z*Z*")
      l "GET #{ name } options: #{ opts }"

      if mode != "octet"
        l "FATAL ERROR ERROR: mode '#{ mode }' is not implemented. Abort."
        send_error_packet(
          ErrorCode::NOT_DEFINED,
          "Mode #{ mode } is not implemented"
        )
        return
      end

      # http://tools.ietf.org/html/rfc2347
      @extensions = Hash[*opts]
      @name = name

      # Handle pxelinux.cfg with a custom script
      if name.start_with?("pxelinux.cfg")

        # We support only mac based configuration
        if match_mac = name.downcase.match(/pxelinux.cfg\/01-(([0-9a-f]{2}[:-]){5}[0-9a-f]{2})/)
          return exec_script( match_mac[1] )
        end

        # If not mac just ignore
        l "ERROR: cannot find #{ name }"
        send_error_packet(ErrorCode::NOT_FOUND, "No found :(")
        return
      end

      begin
        init_sending @filereader.read(name)
      rescue Errno::ENOENT
        l "ERROR: cannot find #{ name }"
        send_error_packet(ErrorCode::NOT_FOUND, "No found :(")
        return
      end

    end

    def set_oack_packet(options)
      # http://tools.ietf.org/html/rfc2347#page-3
      oack = [Opcode::OACK].pack("n")
      d "Packing #{ options.inspect }"
      options.each do |k,v|
        oack += [k,v.to_s].pack("a*xa*x") if not k.empty?
      end
      @current = oack

      l "Sending OACK #{ oack.inspect }"
      send_packet
    end

    def init_sending(data)
      @started = Time.now
      @data = data
      l "Going to send #{ @data.size } bytes"

      # Detect extensions and send oack
      if @extensions["tsize"] == "0"
        set_oack_packet({
          "tsize" => @data.size
        })
        send_packet
        return
      end

      # If no extensions detected start sending data
      next_block
      send_packet
    end

    def exec_script(mac = nil)
      command = "./ltspboot-config"
      if mac
        command += " --mac #{mac}"
      end
      l "Executing script #{ command }"
      child = EM::DeferrableChildProcess.open(command)
      child.callback { |stdout| init_sending stdout }
    end

    # set timeout for the current block
    def set_timeout
      saved = @block_num

      if @retry_count == 0
        l "Tried resending #{ RETRY_COUNT } times. Giving up. #{ @current.inspect }"
        return
      end

      if @retry_count.nil?
        @retry_count = RETRY_COUNT
      end

      @retry_count -= 1
      @timeout = EventMachine::Timer.new(TIMEOUT) do
        d "Resending packet from timeout. Retry #{ @retry_count }/#{ RETRY_COUNT }"
        send_packet
      end
    end

    # Clear timeout for the current block
    def clear_timeout
      if @timeout
        @timeout.cancel()
        @timeout = nil
      end
    end

    def reset_retries
      @retry_count = nil
    end

    def send_error_packet(code, msg)
      # http://tools.ietf.org/html/rfc1350#page-8
      @error = [Opcode::ERROR, code, msg].pack("nna*x")
      l "Sending error #{ code }: #{ msg }"
      send_datagram(@error, @ip, @port)
    end


    # Send current block to the client
    def send_packet
      # Bad internet simulator
      # if Random.rand(100) == 0
      #   puts "skipping #{ @block_num }"
      #   return
      # end

      clear_timeout
      send_datagram(@current, @ip, @port)
      set_timeout
    end

    # Move to sending next block
    def next_block
      @block_num += 1

      block = @data.byteslice((@block_num-1) * BLOCK_SIZE, BLOCK_SIZE)
      @current_block_size = block.size

      d(
        "Sending block #{ @block_num }. " +
        "#{ @block_num*BLOCK_SIZE }...#{ @block_num*BLOCK_SIZE+BLOCK_SIZE }" +
        "(#{ @current_block_size }) of #{ @data.size }"
      )

      @current = [Opcode::DATA, @block_num, block].pack("nna*")
    end

    # Is the current block last block client needs
    def last_block?
      # If we have current block and its size is under BLOCK_SIZE it means in
      # tftp spec that it's the last block.
      @current_block_size && @current_block_size < BLOCK_SIZE
    end

    def handle_error(data)
      super
      l "ABORT"
      clear_timeout
      reset_retries
    end

    def handle_ack(data)
      _, block_num = data.unpack("nn")

      if @error
        l "ACK #{ block_num } for error. Stopping."
        clear_timeout
        return
      end

      if block_num == @block_num
        d "ACK for block #{ block_num } ok."
        reset_retries

        if not last_block?
          next_block
          send_packet
        else
          finish
        end

      elsif block_num == @block_num-1
        d "ACK for previous block #{ block_num }. Resending."
        send_packet
      else
        raise "BAD ACK #{ block_num }, was waiting for #{ @block_num }"
      end

    end

    def finish
      # TODO: close connection?
      l "File sent OK! Sending took #{ Time.now - @started }s"
      clear_timeout
    end

  end

end
