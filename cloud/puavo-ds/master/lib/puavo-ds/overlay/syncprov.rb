class Syncprov < Overlay
  
  def self.add_overlay_config(args)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}syncprov",
              "objectClass" => ['olcSyncProvConfig', 'olcOverlayConfig']
              ).save(false)
  end

  def self.index
    0
  end
end
