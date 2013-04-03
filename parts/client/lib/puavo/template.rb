require 'erb'

module Puavo
  class Template

    def initialize(template_dir)
      @template_dir = template_dir
    end

    def write(filename, version=nil, secure=false)
      template_file = filename

      if version
        template_file = "#{filename}-#{version}"
      end

      conf_template = File.read( File.join(@template_dir, "templates", template_file)
      conf = ERB.new(conf_template, 0, "%<>")

      perm = secure ? 0600 : 0644

      File.open(filename, "w", perm) do |f|
        f.write conf.result
      end

      File.chmod(perm, filename)
    end

  end
end
