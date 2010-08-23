class Overlay < ActiveLdap::Base
  def self.ldap_mapping(args)
    super( :dn_attribute => "olcOverlay",
           :prefix => args[:prefix] )
  end

  def self.create_overlays(db_configuration)
    self.ldap_mapping( :prefix => "olcDatabase=#{db_configuration.olcDatabase}" )
    self.subclasses_order_by_index.each do |_subclass|
      Class.class_eval(_subclass).add_overlay_config(db_configuration)
    end
  end

  def self.subclasses_order_by_index
    self.subclasses.sort{ |a,b| Class.class_eval(a).index <=> Class.class_eval(b).index }
  end
end
