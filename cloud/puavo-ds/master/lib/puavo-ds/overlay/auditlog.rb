class Auditlog < Overlay
  def self.add_overlay_config(args)
    # Save without validation
    self.new('objectClass' => [ 'olcAuditlogConfig', 'olcOverlayConfig' ],
             'olcOverlay' => "{#{ self.index }}auditlog",
             'olcAuditlogFile' => [
               "/var/log/slapd/auditlog/#{ args[:database].olcSuffix }.log" ]) \
        .save
  end

  def self.index
    8
  end
end
