
require "./lib/log"

class CachedFileReader

  def initialize(root)
    @root = root
    @cache = {}
  end

  def read(name)
    name = File.join(@root, name)

    if data = @cache[name]
      return data
    end


    return @cache[name] = File.open(name, "rb").read
  end

end
