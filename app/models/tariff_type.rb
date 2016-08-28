class TariffType < ActiveRecord::Base
  attr_accessible :code, :name

  validates :name, :presence => true
  validates :code, :presence => true,
                   :length => { :is => 3 },
                   :uniqueness => true

  before_validation :fields_to_uppercase

  def to_label
    "#{name} (#{code})"
  end

  def fields_to_uppercase
    if !self.code.blank?
      self[:code].upcase!
    end
  end
end