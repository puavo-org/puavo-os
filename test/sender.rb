
require "minitest/autorun"

require "puavo-tftp/tftpfilesender"

class DummyReader

  def initialize(files)
    @files = files
  end

  def read(name)
    if f = @files[name]
      return f
    else
      raise Errno::ENOENT
    end
  end

end

class DummyFileSender < PuavoTFTP::FileSender

  attr_reader :sent_packets
  attr_reader :test_files

  def initialize(*args)
    super(*args, "/dummyroot")
    @sent_packets = []
    @test_files = {}
    @dr = DummyReader.new @test_files
  end

  def send_datagram(*args)
    @sent_packets.push args
  end

  def read_file(name)
    @dr.read(name)
  end

end

def ev_run(*args)
  EventMachine::run do
    yield EventMachine::open_datagram_socket(
      "127.0.0.1",
      0,
      *args
    )
  end
end

describe PuavoTFTP::FileSender do

  it "sends small file in one package" do
    ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|
      sender.on_data do |data, ip, port|
        assert_equal(
          data,
          "\x00\x03\x00\x01small content"
        )
        EM::stop_event_loop
      end


      sender.test_files["small"] = "small content"
      sender.handle_get([
        PuavoTFTP::Opcode::RRQ,
        "small",
        "octet"
      ].pack("na*xa*x"))
    end
  end

  it "sends larger file in two packages" do
    ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

      sender.on_data do |data, ip, port|
        _, num = data.unpack("nn")

        sender.handle_ack([
          PuavoTFTP::Opcode::ACK,
          num
        ].pack("nn"))
      end

      sender.on_end do
        assert_equal(
          "\x00\x03\x00\x01" + "X"*512,
          sender.sent_packets[0][0]
        )

        assert_equal(
          "\x00\x03\x00\x02" + "X"*(600-512),
          sender.sent_packets[1][0]
        )

        EM::stop_event_loop
      end

      sender.test_files["larger"] = "X"*600
      sender.handle_get([
        PuavoTFTP::Opcode::RRQ,
        "larger",
        "octet"
      ].pack("na*xa*x"))

    end
  end

  it "sends an empty packge as last packet when sending mod 512 file" do
    ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

      sender.on_data do |data, ip, port|
        _, num = data.unpack("nn")
        sender.handle_ack([
          PuavoTFTP::Opcode::ACK,
          num
        ].pack("nn"))
      end

      sender.on_end do
        assert_equal(
          ["\x00\x03\x00\x05", "127.0.0.1", 1234],
          sender.sent_packets.last
        )
        EM::stop_event_loop
      end

      sender.test_files["mod512"] = "X"*512*4
      sender.handle_get([
        PuavoTFTP::Opcode::RRQ,
        "mod512",
        "octet"
      ].pack("na*xa*x"))

    end
  end

  it "calls on_end on nonexistent files" do
    ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

      sender.on_data do |data, ip, port|
        _, num = data.unpack("nn")
        sender.handle_ack([
          PuavoTFTP::Opcode::ACK,
          num
        ].pack("nn"))
      end

      sender.on_end do
        assert_equal(
          ["\x00\x05\x00\x01No found :(\x00", "127.0.0.1", 1234],
          sender.sent_packets.last
        )
        EM::stop_event_loop
      end

      sender.handle_get([
        PuavoTFTP::Opcode::RRQ,
        "notfound",
        "octet"
      ].pack("na*xa*x"))

    end
  end


  describe "extension" do

    describe "tsize" do
      it "sents oack for tsize extension" do
        ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

          sender.on_data do |data, ip, port|
            assert_equal(data, "\x00\x06tsize\x00700\x00")
            EM::stop_event_loop
          end

          sender.test_files["somefile"] = "X"*700
          sender.handle_get([
            PuavoTFTP::Opcode::RRQ,
            "somefile",
            "octet",
            "tsize",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end
    end


    describe "blksize" do
      it "sents oack for block extension" do
        ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

          sender.on_data do |data, ip, port|
            assert_equal(data, "\x00\x06blksize\x0010\x00")
            EM::stop_event_loop
          end

          sender.test_files["somefile"] = "X"*700
          sender.handle_get([
            PuavoTFTP::Opcode::RRQ,
            "somefile",
            "octet",
            "blksize",
            "10",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end

      it "sents blksize sized packages" do
        ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

          handlers = [
            lambda do |data|
              sender.handle_ack([
                PuavoTFTP::Opcode::ACK, 0
              ].pack("nn"))
            end,

            lambda do |data|
              assert_equal(
                "\x00\x03\x00\x01XXXXXXXXXX",
               data
              )
              _, num = data.unpack("nn")
              puts "SENDING ACK TO SERVER #{ num }"
              sender.handle_ack([
                PuavoTFTP::Opcode::ACK,
                num
              ].pack("nn"))
            end,

            lambda do |data|
              assert_equal(
                "\x00\x03\x00\x02XX",
               data
              )
              _, num = data.unpack("nn")
              puts "SENDING ACK TO SERVER #{ num }"
              sender.handle_ack([
                PuavoTFTP::Opcode::ACK,
                num
              ].pack("nn"))
            end,
          ]

          sender.on_end do
            EM::stop_event_loop
          end

          count = -1

          sender.on_data do |data, ip, port|
            count += 1
            if h = handlers[count]
              h.call data
            end
          end

          sender.test_files["blksizetest"] = "X"*12
          sender.handle_get([
            PuavoTFTP::Opcode::RRQ,
            "blksizetest",
            "octet",
            "blksize",
            "10",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end

    end


  end

  it "resends package if I send ack for previous package" do
    ev_run DummyFileSender, "127.0.0.1", 1234 do |sender|

      handlers = [
        lambda do |data|
          sender.handle_ack([
            PuavoTFTP::Opcode::ACK, 1
          ].pack("nn"))
        end,

        lambda do |data|
          assert_equal(
            "\x00\x03\x00\x02" + "Y"*(512),
            data
          )
          sender.handle_ack([
            PuavoTFTP::Opcode::ACK, 1
          ].pack("nn"))
        end,

        lambda do |data|
          assert_equal(
            "\x00\x03\x00\x02" + "Y"*(512),
            data
          )
          EM::stop_event_loop
        end
      ]

      count = -1
      sender.on_data do |data, ip, port|
        count += 1
        handlers[count].call data
      end

      sender.test_files["file"] = "X"*512 + "Y"*520
      sender.handle_get([
        PuavoTFTP::Opcode::RRQ,
        "file",
        "octet"
      ].pack("na*xa*x"))

    end
  end
end

