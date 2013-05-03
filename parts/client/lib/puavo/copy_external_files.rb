require 'digest/sha1'
require 'fileutils'
require 'puavo'

module Puavo
  module Files

    def self.read_current_files(dirpath)
      file_hashes = {}

      Dir.entries(dirpath).each do |name|
        begin
          File.open(File.join(dirpath, name), "rb") do |f|
            sha1 = Digest::SHA1.new

            while data = f.read(512)
              sha1.update(data)
            end

            file_hashes[name] = { :data_hash => sha1.hexdigest }
          end
        rescue Errno::EISDIR
        end
      end

      return file_hashes
    end

    def self.copy_external_files(external_files, target)
      FileUtils.mkdir_p(target)

      current_files = read_current_files(target)

      external_files.all.each do |ef|
        if current_files[ef.name] &&
          current_files[ef.name][:data_hash] == ef.data_hash
          next
        end

        file_path = File.join(target, ef.name)

        File.open(file_path, "w") do |f|
          STDERR.puts "Writing file #{ file_path }"
          f.write(ef.get_data)
        end

      end

    end
  end
end
