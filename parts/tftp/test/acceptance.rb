
require "minitest/autorun"
require "fileutils"
require "digest/sha1"

require "./lib/tftpserver"

DIR = File.dirname File.expand_path __FILE__
TMP = File.join(DIR, "tmp")
ROOT = File.join(DIR, "tftpboot")
PORT = 1234

def tftp_hpa_fetch(name)
  # TODO: assert exit status
  `tftp -m octet localhost #{ PORT } -c get #{ name }`
end

def sha1sum(file)
  Digest::SHA1.hexdigest File.open(file, "r").read
end


class ServerThread < Thread
  def initialize
    super do
      EventMachine::run do
        EventMachine::open_datagram_socket("0.0.0.0", PORT, TFTP::Server, ROOT)
      end
    end
  end
  def stop
    EventMachine::stop_event_loop
  end
end


describe "Test TFTP::Server with tftp-hpa client" do

  before do
    @ev = ServerThread.new
    sleep 0.2
    puts "TFTP Server started"

    FileUtils.rm_r(TMP) rescue Errno::ENOENT
    FileUtils.mkdir(TMP)
    Dir.chdir(TMP)
    puts "files created"
  end

  after do
    puts "TFTP Server stopping..."
    @ev.stop
    @ev.join()
    puts "Stopped."
    FileUtils.rm_r(TMP)
  end

  [
   "small",
   "kuva.jpg",
   "mod512",
   "under512"
  ].each do |name|
    it "fetch small file" do
      tftp_hpa_fetch(name)
      sha1sum(File.join(ROOT, name)).must_equal(
        sha1sum(File.join(TMP, name))
      )
    end
  end

end
