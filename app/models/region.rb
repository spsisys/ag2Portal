class Region < ActiveRecord::Base
  belongs_to :country
  attr_accessible :country_id, :name,
                  :created_by, :updated_by

  validates :name,        :presence => true
  validates :country_id,  :presence => true

  has_many :provinces
  has_many :shared_contacts
  def to_label
    "#{name} (#{country.name})"
  end

  def name_and_country
    self.name + " (" + self.country.name + ")"
  end
end
