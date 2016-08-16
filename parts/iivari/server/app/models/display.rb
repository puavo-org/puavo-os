class Display < OrganisationData
  belongs_to :channel

  validates_presence_of :hostname

  def self.find_all_by_school_id(school_id, puavo_api)
    # FIXME: get devices by type
    puavo_devices = puavo_api.devices.find_by_school_id(school_id)
    all.select do |display|
      puavo_devices.map{ |d| d.puavoHostname.to_s }.include?(display.hostname)
    end
  end
end
