class PaymentMethod < ActiveRecord::Base
  belongs_to :organization
  attr_accessible :default_interest, :description, :expiration_days, :flow, :organization_id

  has_many :suppliers
  has_many :clients
  has_many :purchase_orders
  has_many :receipt_notes
  has_many :offer_requests
  has_many :offers
  has_many :supplier_invoices
  has_many :delivery_notes
  has_many :sale_offers

  has_paper_trail

  validates :description,   :presence => true,
                            :uniqueness => { :scope => :organization_id }
  validates :flow,          :presence => true,
                            :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 3 }
  validates :organization,  :presence => true

  # Scopes
  scope :by_description, -> { order(:description) }
  #
  scope :collections, -> { where("flow = 3 OR flow = 1").by_description }
  scope :payments, -> { where("flow = 3 OR flow = 2").by_description }
  scope :collections_belong_to_organization, -> o { where("(flow = 3 OR flow = 1) AND organization_id = ?", o).by_description }
  scope :payments_belong_to_organization, -> o { where("(flow = 3 OR flow = 2) AND organization_id = ?", o).by_description }

  before_destroy :check_for_dependent_records

  def to_label
    "#{description}"
  end

  def flow_label
    flow_label = case flow
      when 1 then I18n.t('activerecord.attributes.payment_method.flow_1')
      when 2 then I18n.t('activerecord.attributes.payment_method.flow_2')
      when 3 then I18n.t('activerecord.attributes.payment_method.flow_3_show')
      else 'N/A'
    end
  end

  private

  def check_for_dependent_records
    # Check for suppliers
    if suppliers.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_suppliers'))
      return false
    end
    # Check for purchase orders
    if purchase_orders.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_purchase_orders'))
      return false
    end
    # Check for receipt notes
    if receipt_notes.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_receipt_notes'))
      return false
    end
    # Check for offer requests
    if offer_requests.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_offer_requests'))
      return false
    end
    # Check for offers
    if offers.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_offers'))
      return false
    end
    # Check for supplier invoices
    if supplier_invoices.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_supplier_invoices'))
      return false
    end
    # Check for delivery notes
    if delivery_notes.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_delivery_notes'))
      return false
    end
    # Check for sale offers
    if sale_offers.count > 0
      errors.add(:base, I18n.t('activerecord.models.payment_method.check_for_sale_offers'))
      return false
    end
  end
end
