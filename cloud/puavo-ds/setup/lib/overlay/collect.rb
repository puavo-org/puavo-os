class Collect < Overlay
  
  def self.add_overlay_config(db_configuration)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}collect",
              "objectClass" => ['olcCollectConfig', 'olcOverlayConfig'],
              "olcCollectInfo" => "ou=Hosts,#{db_configuration.olcSuffix} parentNode" ).save(false)
  end

  def self.index
    6
  end
end
