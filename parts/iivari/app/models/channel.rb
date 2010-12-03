class Channel < OrganisationData
  has_many :slides, :order => "position"
  has_many :displays

  validates_presence_of :name
end
