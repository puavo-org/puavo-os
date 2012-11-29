
require "minitest/autorun"
require "fileutils"
require "digest/sha1"

DIR = File.dirname File.expand_path __FILE__
TMP = File.join(DIR, "tmp")
ROOT = File.join(DIR, "tftpboot")

def tftp_hpa_fetch(name)
  `tftp -m octet localhost -c get #{ name }`
end

def sha1sum(file)
  Digest::SHA1.hexdigest File.open(file, "r").read
end

describe "Test TFTP::Server with tftp-hpa client" do

  before do
    FileUtils.rm_r(TMP) rescue Errno::ENOENT
    FileUtils.mkdir(TMP)
    Dir.chdir(TMP)
  end

  after do
    FileUtils.rm_r(TMP)
  end

  ["small", "kuva.jpg", "mod512", "under512"].each do |name|
    it "fetch small file" do
      tftp_hpa_fetch(name)
      sha1sum(File.join(ROOT, name)).must_equal(
        sha1sum(File.join(TMP, name))
      )
    end
  end


end


