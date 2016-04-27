require 'puavo/gems'
require 'optparse'
require 'http'
require 'puavo/etc'

class PuavoImageClient

  def self.download(options)
    sha256 = Digest::SHA256.new
    response = HTTP.get(options[:download_url])

    File.open(options[:output_file], "w") do |file|
      while buffer = response.readpartial(4096)
        sha256.update(buffer) if options.has_key?(:sha256)
        file.write(buffer)
      end
    end

    if options.has_key?(:sha256) && sha256.hexdigest != options[:sha256]
      raise SHA256MismatchError, "Error: SHA256 mismatch, sha256: #{ sha256.hexdigest }"
    end
  end

  class SHA256MismatchError < RuntimeError;  end
end
