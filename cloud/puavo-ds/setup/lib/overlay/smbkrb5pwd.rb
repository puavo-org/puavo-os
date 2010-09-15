class Smbkrb5pwd < Overlay
    # Save without validation
  def self.add_overlay_config(db_configuration)
    self.new( 'objectclass' => ['olcSmbKrb5PwdConfig', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index}}smbkrb5pwd",
              'olcSmbKrb5PwdEnable' => ['krb5', 'samba'],
              'olcSmbKrb5PwdMustChange' => '2592012',
              'olcSmbKrb5PwdKrb5Realm' => "EDU" + 
              db_configuration.olcSuffix.to_s.match(/dc=edu,dc=([^,]+),/)[1].upcase,
              'olcSmbKrb5PwdRequiredClass' => "puavoEduPerson" ).save(false)
  end

  def self.index
    6
  end
end
