class Display < ActiveRecord::Base
  belongs_to :channel

  validates_presence_of :hostname
end
