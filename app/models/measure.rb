class Measure < ActiveRecord::Base
  attr_accessible :description

  has_paper_trail

  validates :description, :presence => true

  has_many :products
  has_many :purchase_prices

  before_destroy :check_for_dependent_records

  def to_label
    "#{description}"
  end

  private

  def check_for_dependent_records
    # Check for products
    if products.count > 0
      errors.add(:base, I18n.t('activerecord.models.measure.check_for_products'))
    return false
    end
  end
end
