
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
  end

  # http://tools.ietf.org/html/rfc1350#page-10
  module ErrorCode
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

    def handle_opcode(code, *args)
      if handler = OPCODE_HANDLERS[code]
        send(handler, *args)
      else
        log "Unknown opcode #{ req[0] } #{ data.inspect }"
      end
    end

    def handle_error(num, *args)
      l "ERROR: #{ ERROR_DESCRIPTIONS[num] }"
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

    def receive_data(data)
      debug "Server got data #{ data.inspect }"
      req = data.unpack("nZ*Z*")
      handle_opcode(req[0], req[1], req[2])
    end

    def to_s
      "<Server fixed>"
    end

    def handle_get(name, mode)

      # Faster?
      # get_peername[2,6].unpack("nC4")
      port, ip = Socket.unpack_sockaddr_in(get_peername)

      if mode != "octet"
        warn "Mode #{ mode } is not implemented"
        return
      end

      # Create dedicated TFTP file sender server for this client on a ephemeral
      # (random) port
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0", 0, FileSender, ip, port, @filereader
      )

      sender.tftp_send(name)

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
    def tftp_send(name)
      @name = name

      begin
        data = @filereader.read(name)
      rescue Errno::ENOENT
        l "Cannot find file #{ name }"
        error(ErrorCode::NOT_FOUND, "No found :(")
        return
      end

      l "Sending #{ data.size } bytes"
      @data = data
      next_block
      send_packet
    end

    # set timeout for the current block
    def set_timeout
      saved = @block_num

      if @retry_count == 0
        l "Tried resending #{ RETRY_COUNT } times. Giving up."
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

    def error(code, msg)
    # http://tools.ietf.org/html/rfc1350#page-8
    @error = true
    @block_num = 1
    @current = [Opcode::ERROR, code, msg].pack("nna*x")
    l "Sending error #{ code }: #{ msg }"
    send_packet
    end

    # Send current block to the client
    def send_packet
      # Bad internet simulator
      # if Random.rand(400) == 0
      #   d "skipping #{ @block_num }"
      #   return
      # end

      clear_timeout
      send_datagram(@current, @ip, @port)
      set_timeout
    end

    # Move to sending next block
    def next_block
      @block_num += 1

      block = @data.byteslice( (@block_num-1) * BLOCK_SIZE, BLOCK_SIZE)
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

    def receive_data(data)
      # port, ip = Socket.unpack_sockaddr_in(get_peername)
      # d "Sender got data from #{ ip }:#{ port } #{ data.inspect }"
      req = data.unpack("nn")
      handle_opcode(req[0], req[1])
    end

    def handle_ack(block_num)

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
          l "File sent ok!"
          clear_timeout
        end

      elsif block_num == @block_num-1
        d "ACK for previous block #{ block_num }. Resending."
        send_packet
      else
        raise "BAD ACK #{ block_num }, was waiting for #{ @block_num }"
      end

    end

  end
end
