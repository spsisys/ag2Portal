class ReceiptNoteItem < ActiveRecord::Base
  belongs_to :receipt_note
  belongs_to :purchase_order
  belongs_to :purchase_order_item
  belongs_to :product
  belongs_to :tax_type
  belongs_to :store
  belongs_to :work_order
  belongs_to :charge_account
  belongs_to :project
  attr_accessible :code, :description, :discount, :discount_pct, :price, :quantity,
                  :receipt_note_id, :purchase_order_id, :purchase_order_item_id,
                  :product_id, :tax_type_id, :store_id, :work_order_id,
                  :charge_account_id, :project_id

  has_many :supplier_invoice_items

  has_paper_trail

  validates :receipt_note,    :presence => true
  validates :description,     :presence => true,
                              :length => { :maximum => 40 }
  validates :product,         :presence => true
  validates :tax_type,        :presence => true
  validates :store,           :presence => true
  validates :work_order,      :presence => true
  validates :charge_account,  :presence => true
  validates :project,         :presence => true
  validates :quantity,        :numericality => true
  validates :price,           :numericality => true

  before_destroy :check_for_dependent_records
  before_validation :fields_to_uppercase
  before_save :check_for_new_stock_and_price
  after_create :update_stock_and_price_on_create
  after_update :update_stock_and_price_on_update

  def fields_to_uppercase
    if !self.description.blank?
      self[:description].upcase!
    end
    true
  end

  #
  # Calculated fields
  #
  def amount
    quantity * (price - discount)
  end

  def tax
    (tax_type.tax / 100) * amount if !tax_type.nil?
  end

  def net
    amount - (amount * (receipt_note.discount_pct / 100)) if !receipt_note.discount_pct.blank?
  end

  def net_tax
    tax - (tax * (receipt_note.discount_pct / 100)) if !receipt_note.discount_pct.blank?
  end

  private

  # Before destroy
  def check_for_dependent_records
    # Check for supplier invoice items
    if supplier_invoice_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.receipt_note_item.check_for_supplier_invoices'))
      return false
    end
  end
  
  #
  # Triggers to update linked models
  #
  # Before save (create & update)
  # Creates new Stock (unless product type 2) & PurchasePrice if don't exist
  def check_for_new_stock_and_price
    if product.product_type.id != 2
      _stock = Stock.find_by_product_and_store(product, store)
      if _stock.nil?
        # Insert a new empty record if Stock doesn't exist
        _stock = Stock.create(product: product, store: store, initial: 0, current: 0, minimum: 0, maximum: 0, location: nil)
      end
    end
    _purchase_price = PurchasePrice.find_by_product_and_supplier(product, receipt_note.supplier)
    if _purchase_price.nil?
      # Insert a new empty record if PurchasePrice doesn't exist
      _purchase_price = PurchasePrice.create(product: product, supplier: receipt_note.supplier, code: code, price: 0, measure: product.measure, factor: 1)
    end
    true
  end
    
  # After create
  # Updates Stock & PurchasePrice (current)
  def update_stock_and_price_on_create
    _current_stock = 0
    _current_average_price = 0
    _new_average_price = 0
    # Update current Stock (unless product type 2) attributes: current
    if product.product_type.id != 2
      _stock = Stock.find_by_product_and_store(product, store)
      if !_stock.nil?
        _stock.current += quantity
        if !_stock.save
          return false
        end
      end
    end 
    # Update current PurchasePrice attributes: price
    # Warning: If current PurchasePrice is favorite, Product reference_price will be updated automatically: Do not update it later!
    _purchase_price = PurchasePrice.find_by_product_and_supplier(product, receipt_note.supplier)
    if _purchase_price.nil?
      _purchase_price.price = price
      if !_purchase_price.save
        return false
      end
    end
    # Update current Product attributes: last_price, average_price
    _current_stock = product.stock
    _current_average_price = product.average_price
    _new_average_price = ((_current_average_price * _current_stock) + amount) / (_current_stock + quantity)
    product.attributes = { last_price: price, average_price: _new_average_price }
    if !product.save
      return false
    end
    true
  end
  
  # After update
  # Updates Stock & PurchasePrice (current and previous)
  def update_stock_and_price_on_update
    
  end
end
