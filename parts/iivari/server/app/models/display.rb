class Display < OrganisationData
  belongs_to :channel

  validates_presence_of :hostname
end
