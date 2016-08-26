class Overlay < ActiveLdap::Base

  def self.ldap_mapping(args)
    super( :dn_attribute => "olcOverlay",
           :prefix => args[:prefix] )
  end

  def self.create_overlays(args)
    self.ldap_mapping( :prefix => "olcDatabase=#{args[:database].olcDatabase}" )
    # Find classes for overlay configurations. If you like to add new overlay configuration
    # you have to only create new child class for Overlay.
    self.subclasses_order_by_index.each do |_subclass|
      Class.class_eval(_subclass.to_s).add_overlay_config(args)
    end
  end

  def self.subclasses_order_by_index
    self.subclasses.sort{ |a,b| Class.class_eval(a.to_s).index <=> Class.class_eval(b.to_s).index }
  end
end
