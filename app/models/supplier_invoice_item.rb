class SupplierInvoiceItem < ActiveRecord::Base
  belongs_to :supplier_invoice
  belongs_to :receipt_note
  belongs_to :receipt_note_item
  belongs_to :purchase_order
  belongs_to :purchase_order_item
  belongs_to :product
  belongs_to :tax_type
  belongs_to :work_order
  belongs_to :charge_account
  belongs_to :project
  attr_accessor :thing
  attr_accessible :code, :description, :discount, :discount_pct, :price, :quantity,
                  :supplier_invoice_id, :receipt_note_id, :receipt_note_item_id,
                  :product_id, :tax_type_id, :work_order_id, :charge_account_id,
                  :purchase_order_id, :purchase_order_item_id,
                  :project_id, :thing

  has_paper_trail

  validates :description,         :presence => true,
                                  :length => { :maximum => 40 }
  validates :product,             :presence => true
  validates :tax_type,            :presence => true
  #validates :work_order,         :presence => true
  validates :charge_account,      :presence => true
  validates :project,             :presence => true
  validates :receipt_note_item,   :presence => true, :if => "!receipt_note_id.blank?"
  validates :purchase_order_item, :presence => true, :if => "!purchase_order_id.blank?"

  before_validation :fields_to_uppercase

  def fields_to_uppercase
    if !self.description.blank?
      self[:description].upcase!
    end
  end

  def charge_account_code
    charge_account.blank? ? '' : charge_account.full_code
  end

  #
  # Calculated fields
  #
  def amount
    quantity * net_price
  end

  def tax
    (tax_type.tax / 100) * amount if !tax_type.nil?
  end

  def net
    if supplier_invoice && !supplier_invoice.discount_pct.blank?
      amount - (amount * (supplier_invoice.discount_pct / 100))
    else
      amount
    end
  end

  def net_tax
    if supplier_invoice && !supplier_invoice.discount_pct.blank?
      tax - (tax * (supplier_invoice.discount_pct / 100))
    else
      tax
    end
  end

  def net_price
    price - discount
  end
end
