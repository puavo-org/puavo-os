class Slide < ActiveRecord::Base
  belongs_to :channel
  
  acts_as_list

  attr_accessor :slide_html

end
