require 'digest/sha1'
require 'puavo'

def files_with_hashes(dirpath)
  file_hashes = {}

  Dir.entries(dirpath).each do |name|
    begin
      File.open(File.join(dirpath, name), "rb") do |f|

        sha1 = Digest::SHA1.new

        while data = f.read(512)
          sha1.update(data)
        end

        file_hashes[name] = {
          :data_hash => sha1.hexdigest
        }
      end
    rescue Errno::EISDIR
    end
  end

  return file_hashes
end

def copy_external_files(external_files, target)
  current_files = files_with_hashes(target)

  external_files.all.each do |ef|
    if current_files[ef.name] &&
      current_files[ef.name][:data_hash] == ef.data_hash
      next
    end

    file_path = File.join(target, ef.name)

    File.open(file_path, "w") do |f|
      f.write(ef.get_data)
    end

  end
end


if __FILE__ == $0
  c = Puavo::Client::Base.new("localhost:3000", "albus", "albus", false)
  copy_external_files(c.external_files, "/home/vagrant/external_files")
end
