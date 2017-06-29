class Unique < Overlay
  
  def self.add_overlay_config(args)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}unique",
              "objectClass" => ['olcUniqueConfig', 'olcOverlayConfig'],
              "olcUniqueURI" => ["ldap:///ou=People,#{args[:database].olcSuffix}?uid?sub",
                                 "ldap:///ou=People,#{args[:database].olcSuffix}?mail?sub",
                                 "ldap:///ou=People,#{args[:database].olcSuffix}?homeDirectory?sub",
                                 "ldap:///ou=Hosts,#{args[:database].olcSuffix}?puavoHostname?sub",
                                 "ldap:///?sambaSID?sub"] ).save(false)
  end

  def self.index
    1
  end
end
