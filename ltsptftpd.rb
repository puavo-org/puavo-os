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
  end

  def process(request)
    filename = request['filename']

    case request['opcode']
    when TFTPOpCode::READ
      if filename.eql?(@filename)
        options = request['options']
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
                ack_options[key] = @data.size
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
      if @sent_bytes >= @data.size
        # All the data is sent, don't send anything
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

  def parse_request(data)
    request = Hash.new

    tmp_opcode = data.unpack("n")

    case tmp_opcode[0]
    when TFTPOpCode::READ

      tmp = data.unpack("nZ*Z*Z*Z*Z*Z*Z*Z*")
      opcode = tmp[0]

      request['opcode'] = tmp[0]

      request['filename'] = tmp[1]
      request['mode'] = tmp[2]

      if request['filename'].nil? or request['filename'].empty?
        puts "Filename missing!"
        return
      end

      if request['mode'].nil? or request['mode'].empty?
        puts "Mode missing!"
        return
      end

      if request['mode'].downcase.eql?("netascii") or request['mode'].downcase.eql?("octet")
        puts "Mode: #{request['mode']}"
        puts "Filename: #{request['filename']}"
      else
        puts "Unsupported mode: #{request['mode']}"
      end
 
      request['options'] = Hash[*tmp[3..-1]]

      # FIXME - where does this come from?
      if request['options'].has_key?("")
        request['options'].delete("")
      end

      puts "Options: #{request['options']}"
    when TFTPOpCode::ACK
      tmp = data.unpack("nn")
      request['opcode'] = tmp[0]
      request['block'] = tmp[1]
    end

    return request
  end

  def receive_data(data)
    request = parse_request(data)

    if !request
      puts "Parsing request failed, not responding"
      return
    end

    port, ip = Socket.unpack_sockaddr_in(get_peername)
    client_key = "#{ip}:#{port}"

    case request['opcode']
    when TFTPOpCode::READ
      filename = request['filename']
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

      response = client.process(request)

      if response and response.size > 0
        send_data response
      end
    when TFTPOpCode::ACK
      client = @clients[client_key]

      if client
        response = client.process(request)

        if response and response.size > 0
          send_data response
        end
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
