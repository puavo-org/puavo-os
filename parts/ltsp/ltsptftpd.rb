#!/usr/bin/ruby

require 'socket'
require 'eventmachine'

class TFTPOpCode
  READ = 1
  WRITE = 2
  DATA = 3
  ACK = 4
  ERROR = 5
  OACK = 6
end

# Class to

class TFTPRead
  STATE_NONE = 0
  STATE_WAIT_FOR_READ_ACK = 1
  STATE_WAIT_FOR_OACK_ACK = 2

  def initialize(client, filename, data)
    @state = STATE_NONE
    @client = client
    @data = data
    @retransmit = 0
    @blocknum = 0
    @blocksize = 512
    @timeout = 10
    @filename = filename
    @sent_bytes = 0
    @total_size = data.size
  end

  def process(opcode, blocknum, filename, options)
    case opcode
    when TFTPOpCode::READ
      if filename.eql?(@filename)
        ack_options = Hash.new

        if options
          options.each_pair do |key, value|
            case key.downcase
              when "blksize"
                ack_options[key] = value
                @blocksize = value.to_i
              when "timeout"
                ack_options[key] = value
                @timeout = value.to_i
              when "tsize"
                ack_options[key] = @total_size
            end
          end
        end

        if !ack_options.empty?
          return send_oack(@blocknum, ack_options)
        else
          send_more_data
        end
      end
    when TFTPOpCode::ACK
      if @sent_bytes >= @total_size
        # All the data is sent, don't send anything
        @data = nil
        return
      end

      send_more_data
    end
  end

  def send_more_data
    @blocknum += 1
    packet = [ TFTPOpCode::DATA, @blocknum % 65536, @data.byteslice(@sent_bytes, @blocksize) ].pack("nna*")
    @sent_bytes += @blocksize

    return packet
  end

  def send_oack(blocknum, options)
    option_data = ""

    options.each_pair do |key, value|
      option_data.insert(-1, [key, "#{value}"].pack("Z*Z*"))
    end

    [ TFTPOpCode::OACK ].pack("n") + option_data
  end

end

class TFTPServer < EventMachine::Connection
  def initialize
    @clients = Hash.new
  end

  def receive_data(data)
#    request = parse_request(data)

#    if !request
#      puts "Parsing request failed, not responding"
#      return
#    end

    port, ip = Socket.unpack_sockaddr_in(get_peername)
    client_key = "#{ip}:#{port}"

    opcode = data.unpack("n")[0]

    if TFTPOpCode::ACK == opcode
      tmp = data.unpack("nn")
      blocknum = tmp[1]

      client = @clients[client_key]

      if client
        response = client.process(opcode, blocknum, nil, nil)

        if response and response.size > 0
          send_data response
        end
      end
    elsif TFTPOpCode::READ == opcode
      puts "READ"
      tmp = data.unpack("nZ*Z*Z*Z*Z*Z*Z*Z*")

      filename = tmp[1]
      mode = tmp[2].downcase

      if filename.nil? or filename.empty?
        puts "Filename missing!"
        return
      end

      if mode.nil? or mode.empty?
        puts "Mode missing!"
        return
      end

      if mode.eql?("netascii") or mode.eql?("octet")
        puts "Mode: #{mode}"
        puts "Filename: #{filename}"
      else
        puts "Unsupported mode: #{mode}"
        return
      end
 
      options = Hash[*tmp[3..-1]]

      # FIXME - where does this come from?
      if options.has_key?("")
        options.delete("")
      end

      puts "Options: #{options}"

      contents = ""

      begin
        file = File.open(filename, "rb")
        contents = file.read
      rescue
        send_data [ TFTPOpCode::ERROR, 1, "File not found." ].pack("nnZ*")
        return
      end

      if @clients.has_key?(client_key)
        @clients.delete(client_key)
      end

      client = TFTPRead.new(client_key, filename, contents)
      @clients[client_key] = client

      response = client.process(opcode, 0, filename, options)

      if response and response.size > 0
        send_data response
      end
    end

  end
end

begin
  Dir.chroot("/var/lib/tftpboot/")
  Dir.chdir("/")
rescue Errno::EPERM
  # probably not running as root
  Dir.chdir(dir)
end


EventMachine::run do
  EventMachine::open_datagram_socket("0.0.0.0", 69, TFTPServer)
end
