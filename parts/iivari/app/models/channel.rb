class Channel < OrganisationData
  has_many :slides
  has_many :displays

  validates_presence_of :name
end
