class Constraint < Overlay
    # Save without validation
  def self.add_overlay_config(db_configuration)
    self.new( 'objectclass' => ['olcConstraintConfig', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index}}constraint",
              'olcConstraintAttribute' => ["puavoSchool set \"(this/puavoSchool/puavoSchoolAdmin* | [#{db_configuration.olcSuffix}]/owner* & user)\""] ).save(false)
  end

  def self.index
    5
  end
end
