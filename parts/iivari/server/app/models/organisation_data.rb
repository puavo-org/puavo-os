class OrganisationData < ActiveRecord::Base
  self.abstract_class = true

  def self.conditions
    { :find => where(:organisation => Organisation.current.key),
      :create => { :organisation => Organisation.current.key } }
  end

  def initialize(*args)
    super
    self.organisation = Organisation.current.key
  end


  def self.all(*args)
    with_scope( conditions ) do
      super
    end
  end
  def self.create(*args)
    with_scope( conditions ) do
      super
    end
  end

  def self.update(*args)
    with_scope( conditions ) do
      super
    end
  end
  def self.find(*args)
    with_scope( conditions ) do
      super
    end
  end

  def self.method_missing(*args)
    with_scope( conditions ) do
      super
    end
  end
end
