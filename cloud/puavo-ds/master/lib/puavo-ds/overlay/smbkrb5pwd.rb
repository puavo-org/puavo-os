class Smbkrb5pwd < Overlay
    # Save without validation
  def self.add_overlay_config(args)
    self.new( 'objectclass' => ['olcSmbKrb5PwdConfig', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index}}smbkrb5pwd",
              'olcSmbKrb5PwdEnable' => ['krb5', 'samba'],
              'olcSmbKrb5PwdMustChange' => '2592012',
              'olcSmbKrb5PwdKrb5Realm' => args[:kerberos_realm],
              'olcSmbKrb5PwdRequiredClass' => "puavoEduPerson" ).save(false)
  end

  def self.index
    6
  end
end
