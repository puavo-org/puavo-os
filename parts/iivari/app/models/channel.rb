class Channel < OrganisationData
  has_many :slides

  validates_presence_of :name
end
