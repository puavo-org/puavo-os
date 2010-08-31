class Unique < Overlay
  
  def self.add_overlay_config(db_configuration)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}unique",
              "objectClass" => ['olcUniqueConfig', 'olcOverlayConfig'],
              "olcUniqueURI" => ["ldap:///ou=People,#{db_configuration.olcSuffix}?uid?sub",
                                 "ldap:///ou=People,#{db_configuration.olcSuffix}?mail?sub",
                                 "ldap:///ou=People,#{db_configuration.olcSuffix}?homeDirectory?sub",
                                 "ldap:///?sambaSID?sub"] ).save(false)
  end

  def self.index
    1
  end
end
