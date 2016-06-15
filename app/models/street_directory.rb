class StreetDirectory < ActiveRecord::Base
  belongs_to :town
  belongs_to :street_type
  attr_accessible :street_name, :town_id, :street_type_id
end
