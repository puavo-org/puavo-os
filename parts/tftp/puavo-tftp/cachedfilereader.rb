
require "puavo-tftp/log"

# Ruby EvenMachine does not have async file io operations. So workaround just
# by caching everything to memory.
module PuavoTFTP
  class CachedFileReader

    def initialize(root)
      @root = root
      @cache = {}
    end


    def read(name)
      name = File.join(@root, name)
      file = cache_file(name)

      current_mtime = File.mtime(name)

      if file[:mtime] != current_mtime
        log "Reading #{ name } to cache"
        file[:data] = File.open(name, "rb").read
        file[:mtime] = current_mtime
      end

      return file[:data]
    end

    private

    def cache_file(name)
      if ob = @cache[name]
        return ob
      else
        return @cache[name] = {}
      end
    end

  end
end
