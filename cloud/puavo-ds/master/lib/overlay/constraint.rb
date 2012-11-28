class Constraint < Overlay
    # Save without validation
  def self.add_overlay_config(args)
    self.new( 'objectclass' => ['olcConstraintConfig', 'olcOverlayConfig'],
              'olcOverlay' => "{#{self.index}}constraint",
              'olcConstraintAttribute' => ["puavoSchool set \"(this/puavoSchool/puavoSchoolAdmin* | [#{args[:database].olcSuffix}]/owner* & user)\""] ).save(false)
  end

  def self.index
    5
  end
end
