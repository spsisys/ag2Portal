class TaxType < ActiveRecord::Base
  attr_accessible :description, :tax, :expiration,
                  :created_by, :updated_by

  has_paper_trail

  validates :description, :presence => true
  validates :tax,         :presence => true

  #has_many :products

  def to_label
    "#{description} (#{tax})"
  end
end
