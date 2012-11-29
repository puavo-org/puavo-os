
require "eventmachine"
require "socket"
require "pp"

require "./lib/cachedfilereader"
require "./lib/log"

PORT = 69
ROOT = "./test/tftpboot/"

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

  end

  OPCODE_HANDLERS = {
    Opcode::RRQ => :handle_get,
    Opcode::ACK => :handle_ack
  }


  # TFTP server listening on a fixed port (default 69)
  class Server < EventMachine::Connection


    def initialize(root)
      @filereader = CachedFileReader.new(root)
    end

    def receive_data(data)

      log "Server got data #{ data.inspect }"

      req = data.unpack("nZ*Z*")
      if handler = OPCODE_HANDLERS[req[0]]
        send(handler, req[1], req[2])
      else
        error "Unknown opcode #{ req[0].inspect }"
      end

    end

    def handle_get(name, mode)

      # Faster?
      # get_peername[2,6].unpack("nC4")
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      log "GET #{ name } as #{ mode } from #{ ip }:#{ port }"

      if mode != "octet"
        error "Mode #{ mode } is not implemented"
        return
      end

      # Create dedicated TFTP file sender server for this client on a ephemeral
      # (random) port
      sender = EventMachine::open_datagram_socket(
        "0.0.0.0", 0, FileSender, ip, port
      )

      # TODO: parse file&type name from `data` and send contents of it. For now
      # we just send a random image
      begin
        sender.tftp_send(@filereader.read(name))
      rescue Errno::ENOENT

      end
    end

  end

  #TODO http://eventmachine.rubyforge.org/EventMachine/Connection.html#close_connection-instance_method

  # One shot TFTP file sender server listening on ephemeral port
  class FileSender < EventMachine::Connection

    BLOCK_SIZE = 512
    TIMEOUT = 1

    # @param {String} client ip
    # @param {Fixnum} client port
    def initialize(ip, port)
      @ip = ip
      @port = port
      @block_num = 0
      @data = nil
      @block = nil
    end

    def to_s
      "<FileSender to #{ @ip }:#{ @port }>"
    end

    # @param {String} data octet string
    def tftp_send(data)
      log "Sending #{ data.size } bytes to #{ self }"
      @data = data
      next_block
      send
    end

    # set timeout for the current block
    def set_timeout
      saved = @block_num

      @timeout = EventMachine::Timer.new(TIMEOUT) do
        debug "Resending from timeout #{ @block_num }. Was #{ saved }"
        send
      end
    end

    # Clear timeout for the current block
    def clear_timeout
      if @timeout
        debug "clearing #{ @block_num }"
        @timeout.cancel()
        @timeout = nil
      end
    end


    def send_error(code, msg)
    # http://tools.ietf.org/html/rfc1350#page-8
    send_datagram(
      [Opcode::ERROR, @block_num, @block].pack("nna*"),
      @ip,
      @port
    )

    end


    # Send current block to the client
    def send
      # Bad internet simulator
      # if Random.rand(400) == 0
      #   debug "skipping #{ @block_num }"
      #   return
      # end

      # debug "sending block #{ @block_num } with #{ (@block || []).size } bytes"
      clear_timeout

      send_datagram(
        [Opcode::DATA, @block_num, @block].pack("nna*"),
        @ip,
        @port
      )

      set_timeout
    end

    # Move to sending next block
    def next_block
      @block = @data.byteslice(@block_num*BLOCK_SIZE, BLOCK_SIZE)
      @block_num += 1
    end

    # Bytes we are sure the client hase received
    def bytes_sent
      (@block_num-1) * BLOCK_SIZE + @block.size
    end

    # Is the current block last block client needs
    def last_block?
      @block && @block.size != BLOCK_SIZE
    end

    def receive_data(data)
      # port, ip = Socket.unpack_sockaddr_in(get_peername)
      # debug "Sender got data from #{ ip }:#{ port } #{ data.inspect }"

      req = data.unpack("nn")

      if req[0] == Opcode::ACK
        handle_ack(req[1])
      else
        log "Unknown opcode #{ req }"
      end

    end

    def handle_ack(block_num)

      if block_num == @block_num
        debug "ACK for #{ block_num } ok. #{ bytes_sent }/#{ @data.size }, block size was #{ @block.size }"

        if not last_block?
          next_block
          send
        else
          log "ALL DONE"
          clear_timeout
        end

      elsif block_num == @block_num-1
        debug "ACK for previous block #{ block_num }. Resending."
        send
      else
        log "BAD ACK #{ block_num }, was waiting for #{ @block_num }"
      end

    end

  end
end

EventMachine::run do
  EventMachine::open_datagram_socket("0.0.0.0", PORT, TFTP::Server, ROOT)
  log "TFTP server now listening on port #{ PORT }"
end
