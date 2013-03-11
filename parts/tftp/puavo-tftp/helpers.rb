
def symbolize_keys(conf)
  conf.dup.each do |key,value|
    new_key = (key.to_sym rescue key) || key
    conf[ new_key ] = conf.delete(key)
    case value.class.to_s
    when "Array"
      value.each_index do |index|
        if value[index].class == Hash
          conf[ new_key ][index] = symbolize_keys(value[index])
        end
      end
    when "Hash"
      conf[ new_key ] = symbolize_keys(value)
    end
  end
  conf
end
