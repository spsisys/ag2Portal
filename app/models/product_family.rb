class ProductFamily < ActiveRecord::Base
  belongs_to :organization
  attr_accessible :family_code, :max_orders_count, :max_orders_sum, :name, :organization_id, :order_authorization

  has_paper_trail

  validates :name,          :presence => true
  validates :family_code,   :presence => true,
                            :length => { :is => 4 },
                            :uniqueness => { :scope => :organization_id },
                            :format => { with: /\A\d+\Z/, message: :code_invalid },
                            :numericality => { :only_integer => true, :greater_than => 0 }
  validates :organization,  :presence => true

  has_many :products
  has_many :stocks, :through => :products

  before_validation :fields_to_uppercase

  before_destroy :check_for_dependent_records
  def fields_to_uppercase
    if !self.family_code.blank?
      self[:family_code].upcase!
    end
  end

  def to_label
    "#{full_name}"
  end

  def full_name
    full_name = ''
    if !self.family_code.blank?
      full_name = self.family_code
    end
    if !self.name.blank?
      full_name += " " + self.name[0,40]
    end
    full_name
  end
  
  #
  # Calculated fields
  #
  def stock
    stocks.sum("current")
  end

  def stock_by_store(_store)
    stocks.where("store_id = ?", _store).sum("current")
  end

  #
  # Class (self) user defined methods
  #
  def self.by_store(_store)
    joins(:stocks).where("store_id = ?", _store).group("product_families.family_code") 
  end

  private

  def check_for_dependent_records
    # Check for products
    if products.count > 0
      errors.add(:base, I18n.t('activerecord.models.product_family.check_for_products'))
      return false
    end
  end
end
