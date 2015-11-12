require 'redis'

module TempStore

  REDIS = Redis.new

  KEY_PREFIX_AP = 'puavo-wlancontroller:ap:'

  def self.add_accesspoint(hostname)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.set(key, hostname)
  end

  def self.expire_accesspoint(hostname, expire_seconds)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.expire(key, expire_seconds)
  end

  def self.del_accesspoint(hostname)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.del(key)
  end

  def self.get_accesspoints
    ap_keys = REDIS.keys("#{KEY_PREFIX_AP}*")
    ap_keys.empty? ? [] : REDIS.mget(ap_keys)
  end

end
