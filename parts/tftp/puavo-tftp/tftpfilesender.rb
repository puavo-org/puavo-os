
require "eventmachine"

require "puavo-tftp/constants"
require "puavo-tftp/tftpconnection"
require "puavo-tftp/log"

module TFTP

  # One shot TFTP file sender server
  class FileSender < Connection

    BLOCK_SIZE = 512
    TIMEOUT = 1
    RETRY_COUNT = 5

    # @param {String} client ip
    # @param {Fixnum} client port
    def initialize(ip, port, filereader, options)
      @filereader = filereader
      @ip = ip
      @port = port
      @options = options

      @block_num = 0
      @data = nil
      @name = nil

      @block_size = BLOCK_SIZE
      @current = nil
      @current_block_size = nil


      @timer = EventMachine::PeriodicTimer.new(1) do
        return if @packet_sent.nil?

        diff = Time.now - @packet_sent
        if TIMEOUT < diff
          l "Timeout with #{ diff }. Resending."
          send_packet
        end
      end

    end

    def to_s
      "<FileSender:#{ __id__ } #{ @ip }:#{ @port } #{ @name }>"
    end

    def on_end(&cb)
      @on_end = cb
    end

    def on_data(&cb)
      @on_data = cb
    end

    # @param {String} data octet string
    def handle_get(data)
      _, name, mode, *opts = data.unpack("nZ*Z*Z*Z*Z*Z*")
      # http://tools.ietf.org/html/rfc2347
      @extensions = Hash[*opts]
      @name = name

      l "GET(#{ mode }) options: #{ opts }"

      if mode != "octet"
        l "FATAL ERROR ERROR: mode '#{ mode }' is not implemented. Abort."
        send_error_packet(
          ErrorCode::NOT_DEFINED,
          "Mode #{ mode } is not implemented"
        )
        return
      end

      # Check all hooks. Run hook command if regexp match to GET url
      Array(@options[:hooks]).each do |hook|
        if name.match( Regexp.new(hook[:regexp]) )
          return exec_script("#{ hook[:command] } #{ name }")
        end
      end

      begin
        init_sending @filereader.read(name)
      rescue Errno::ENOENT
        l "ERROR: cannot find #{ name }"
        send_error_packet(ErrorCode::NOT_FOUND, "No found :(")
        return
      end

    end

    # Set OACK packet to be sent on next send_packet call
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
      options = {}

      if @extensions["tsize"] == "0"
        options["tsize"] = @data.size
      end

      if @extensions["blksize"]
        options["blksize"] = @extensions["blksize"]
        @block_size = @extensions["blksize"].to_i
      end

      if options.keys.size > 0
        set_oack_packet(options)
        send_packet
        return
      end

      # If no extensions detected start sending data
      set_next_data_packet
      send_packet
    end

    def exec_script(command)
      l "Executing script #{ command }"
      started = Time.now
      child = EM::DeferrableChildProcess.open(command)
      child.callback do |stdout|
        l "Script execution took #{ Time.now - started }s"
        init_sending stdout
      end
    end

    # set timeout for the current block
    def set_timeout

      if @retry_count == 0
        l "Tried resending #{ RETRY_COUNT } times. Giving up. #{ @current.inspect }"
        finish
        return
      end

      if @retry_count.nil?
        @retry_count = RETRY_COUNT
      end

      @retry_count -= 1
      @packet_sent = Time.now
    end

    # Clear timeout for the current block
    def clear_timeout
      @packet_sent = nil
    end

    def reset_retries
      @retry_count = nil
    end

    def send_error_packet(code, msg)
      # http://tools.ietf.org/html/rfc1350#page-8
      @error = [Opcode::ERROR, code, msg].pack("nna*x")
      l "Sending error #{ code }: #{ msg }"
      send_datagram(@error, @ip, @port)
      finish
    end

    # Bad internet simulator
    # def send_datagram(*args)
    #   if Random.rand(10000) == 0
    #     return puts "Skipping #{ @block_num }"
    #   end
    #   super(*args)
    # end

    # Send current block to the client
    def send_packet
      clear_timeout
      send_datagram(@current, @ip, @port)
      @on_data.call(@current, @ip, @port) if not @on_data.nil?
      set_timeout
    end

    # Set DATA packet to be sent on next send_packet call
    def set_next_data_packet
      @block_num += 1

      block = @data.byteslice((@block_num-1) * @block_size, @block_size)
      @current_block_size = block.size

      start = (@block_num-1)*@block_size
      to = (@block_num-1)*@block_size+@current_block_size
      d(
        "Sending block #{ @block_num }. #{ start }...#{ to }" +
        "(#{ @current_block_size }) of #{ @data.size }"
      )

      @current = [Opcode::DATA, @block_num, block].pack("nna*")
    end

    # Is the current block last block client needs
    def last_block?
      # If we have current block and its size is under @block_size it means in
      # tftp spec that it's the last block.
      @current_block_size && @current_block_size < @block_size
    end

    def handle_error(data)
      super
      l "ABORT"
      clear_timeout
      finish
    end

    def handle_ack(data)
      _, block_num = data.unpack("nn")

      if @error
        l "ACK #{ block_num } for error. Stopping."
        clear_timeout
        return
      end

      if block_num == @block_num
        if block_num == 0
          l "ACK for OACK: #{ @extensions }"
        end
        d "ACK for block #{ block_num } ok."
        reset_retries

        if not last_block?
          set_next_data_packet
          send_packet
        else
          took =  Time.now - @started
          speed =  (@data.size / took / 1024 / 1024).round 2
          l "File sent OK! Sent #{ @data.size } bytes in #{ took } seconds (#{speed}MB/s)"
          finish
        end

      elsif block_num == @block_num-1
        d "ACK for previous block #{ block_num }. Resending."
        send_packet
      else
        l "BAD ACK #{ block_num }, was waiting for #{ @block_num }"
      end

    end

    def finish
      @timer.cancel()
      clear_timeout
      close_connection
      @on_end.call() if not @on_end.nil?
    end

  end

end
