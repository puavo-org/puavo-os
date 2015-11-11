require 'redis'

module TempStore

  REDIS = Redis.new

  KEY_ACCESSPOINTS = 'puavo-wlancontroller:accesspoints'

  def self.add_accesspoint(hostname)
    REDIS.sadd(KEY_ACCESSPOINTS, hostname)
  end

  def self.get_accesspoints
    REDIS.smembers(KEY_ACCESSPOINTS)
  end

end
