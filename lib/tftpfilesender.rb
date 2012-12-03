
require "eventmachine"

require "./lib/constants"
require "./lib/tftpconnection"
require "./lib/log"

module TFTP

  # One shot TFTP file sender server
  class FileSender < Connection

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


      # Handle pxelinux.cfg with a custom script
      if name.start_with?("pxelinux.cfg", "/pxelinux.cfg")

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
      if @extensions["tsize"] == "0"
        set_oack_packet({
          "tsize" => @data.size
        })
        send_packet
        return
      end

      # If no extensions detected start sending data
      set_next_data_packet
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
      @on_data.call(@current, @ip, @port) if not @on_data.nil?
      set_timeout
    end

    # Set DATA packet to be sent on next send_packet call
    def set_next_data_packet
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
          set_next_data_packet
          send_packet
        else
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
      l "File sent OK! Sending took #{ Time.now - @started }s"
      clear_timeout
      close_connection
      @on_end.call() if not @on_end.nil?
    end

  end

end
