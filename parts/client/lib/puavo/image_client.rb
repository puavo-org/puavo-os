require 'puavo/gems'
require 'http'

class PuavoImageClient

  def self.download(options)

    file = nil
    case options[:output_file].class.to_s
    when "String"
      file = File.open(options[:output_file], "w")
    when "File"
      file = options[:output_file]
    else
      raise OutputFileError, "Invalid --output-file option"
    end

    sha256 = Digest::SHA256.new
    response = HTTP.get(options[:download_url])

    while buffer = response.readpartial(4096)
      sha256.update(buffer) if options.has_key?(:sha256)
      file.write(buffer)
    end

    if options[:output_file].class == String
      file.close
    end

    if options.has_key?(:sha256) && sha256.hexdigest != options[:sha256]
      raise SHA256MismatchError, "Error: SHA256 mismatch, sha256: #{ sha256.hexdigest }"
    end
  end

  class SHA256MismatchError < RuntimeError;  end
  class OutputFileError < RuntimeError;  end
end
