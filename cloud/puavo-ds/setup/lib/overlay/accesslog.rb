class Accesslog < Overlay
  
  def self.add_overlay_config(db_configuration)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}accesslog",
              "objectClass" => ['olcAccessLogConfig', 'olcOverlayConfig'],
              "olcAccessLogDB" => "cn=accesslog",
              "olcAccessLogOps" => "writes",
              "olcAccessLogSuccess" => "TRUE",
              "olcAccessLogPurge" => "07+00:00 01+00:00" ).save(false)
  end

  def self.index
    8
  end
end
