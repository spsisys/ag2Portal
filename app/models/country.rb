class Country < ActiveRecord::Base
  attr_accessible :name,
                  :created_by, :updated_by

  has_many :shared_contacts
  has_many :regions
end
