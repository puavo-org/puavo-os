
require "eventmachine"
require "socket"
require "pp"

PORT = 69

DATA = File.open("./test/tftpboot/kuva.jpg", "rb") { |f| f.read }
# DATA = "x"*1000
DATA = "x"*512*12

def log(*args)
  puts(*args)
end

def debug(*args)
  args[0] = "DEBUG: " + args[0]
  puts(*args)
end

module TFTPOpCode
  READ = 1
  WRITE = 2
  DATA = 3
  ACK = 4
  ERROR = 5
  OACK = 6
end


# TFTP server listening on a fixed port (default 69)
class TFTPServer < EventMachine::Connection

  def receive_data(data)

    port, ip = Socket.unpack_sockaddr_in(get_peername)

    log "Server got data from #{ ip }:#{ port } #{ data.inspect }"
    # Faster?
    # get_peername[2,6].unpack("nC4")

    # Create dedicated TFTP file sender server for this client on a ephemeral
    # (random) port
    sender = EventMachine::open_datagram_socket(
      "0.0.0.0", 0, TFTPFileSender, ip, port
    )

    # TODO: parse file&type name from `data` and send contents of it. For now
    # we just send a random image
    sender.tftp_send(DATA)

  end

end

class TFTPFileSender < EventMachine::Connection

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

  # @param {String} data octet string
  def tftp_send(data)
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
      [TFTPOpCode::DATA, @block_num, @block].pack("nna*"),
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

    res = data.unpack("nn")

    if res[0] == TFTPOpCode::ACK
      handle_ack(res[1])
    else
      log "Unknown opcode #{ res }"
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

EventMachine::run do
  EventMachine::open_datagram_socket("0.0.0.0", PORT, TFTPServer)
  log "TFTP server now listening on port #{ PORT }"
end
