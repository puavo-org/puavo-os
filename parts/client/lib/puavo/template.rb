require 'erb'

module Puavo
  class Template

    def initialize(template_dir)
      @template_dir = template_dir
    end

    def write(filename, options={})
      template_file = filename

      if options[:version]
        template_file = "#{filename}-#{options[:version]}"
      end

      conf_template = File.read( File.join(@template_dir, "templates", template_file) )
      conf = ERB.new(conf_template, 0, "%<>")

      perm = 0644

      if options[:secure]
        perm = options[:executable] ? 0700 : 0600
      else
        perm = options[:executable] ? 0755 : 0644
      end

      File.open(filename, "w", perm) do |f|
        f.write conf.result
      end

      File.chmod(perm, filename)
    end
  end
end
