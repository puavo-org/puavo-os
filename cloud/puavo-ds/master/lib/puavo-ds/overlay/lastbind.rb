class Lastbind < Overlay
  def self.add_overlay_config(args)
    # Save without validation
    self.new('objectClass' => [ 'olcLastBindConfig', 'olcOverlayConfig' ],
             'olcOverlay' => "{#{ self.index }}lastbind",
             'olcLastBindPrecision' => [ '3600' ]) \
        .save
  end

  def self.index
    7
  end
end
