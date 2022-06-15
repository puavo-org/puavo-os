class Memberof < Overlay
  def self.add_overlay_config(args)
    # Save without validation
    self.new( "olcOverlay" => "{#{self.index}}memberof",
              "objectClass" => ['olcMemberOf', 'olcOverlayConfig'],
              'olcMemberOfGroupOC' => 'puavoEduGroup',
              'olcMemberOfMemberAD' => 'member',
              'olcMemberOfMemberOfAD' => 'memberOf',
              'olcMemberOfDangling' => 'error',
              'olcMemberOfRefInt' => 'TRUE' ).save
    
    # Save without validation
    self.new( 'objectclass' => ['olcMemberOf', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index+1}}memberof",
              'olcMemberOfGroupOC' => 'puavoUserRole',
              'olcMemberOfMemberAD' => 'member',
              'olcMemberOfMemberOfAD' => 'puavoUserRole',
              'olcMemberOfDangling' => 'error',
              'olcMemberOfRefInt' => 'TRUE' ).save

    # Save without validation
    self.new( 'objectclass' => ['olcMemberOf', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index+2}}memberof",
              'olcMemberOfGroupOC' => 'puavoUserRole',
              'olcMemberOfMemberAD' => 'puavoMemberGroup',
              'olcMemberOfMemberOfAD' => 'puavoUserRole',
              'olcMemberOfDangling' => 'error',
              'olcMemberOfRefInt' => 'TRUE' ).save
  end

  def self.index
    2
  end
end
