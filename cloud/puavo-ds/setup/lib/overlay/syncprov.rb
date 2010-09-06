class Syncprov < Overlay
  
  def self.add_overlay_config(db_configuration)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}syncprov",
              "objectClass" => ['olcSyncProvConfig', 'olcOverlayConfig'],
              "olcSpNoPresent" => "TRUE",
              "olcSpReloadHint" => "TRUE" ).save(false)
  end

  def self.index
    0
  end
end
