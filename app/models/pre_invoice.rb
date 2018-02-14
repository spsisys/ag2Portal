class PreInvoice < ActiveRecord::Base
  belongs_to :pre_bill
  belongs_to :invoice_status
  belongs_to :invoice_type
  belongs_to :invoice_operation
  belongs_to :tariff_scheme
  belongs_to :biller, :class_name => 'Company'
  belongs_to :billing_period
  belongs_to :charge_account
  belongs_to :invoice

  attr_accessible :invoice_no, :invoice_date, :consumption, :consumption_real, :consumption_estimated, :consumption_other,
                  :discount_pct, :exemption, :confirmation_date,
                  :pre_bill_id, :invoice_status_id, :invoice_type_id, :tariff_scheme_id, :invoice_operation_id,
                  :biller_id, :billing_period_id, :charge_account_id, :invoice_id, :created_by, :updated_by,
                  :payday_limit, :reading_1_date, :reading_2_date, :reading_1_index, :reading_2_index
  alias_attribute :company, :biller

  has_many :pre_invoice_items, dependent: :destroy
  has_many :pre_invoice_taxes, class_name: "PreInvoiceTax", dependent: :destroy
  has_one :active_supply_invoice

  # Callbacks
  before_save :calculate_and_store_totals

  def total_by_concept(billable_concept=1, includes_cf=false)
    if includes_cf
      pre_invoice_items.joins(tariff: :billable_item).where('billable_items.billable_concept_id = ?', billable_concept.to_i).sum(&:amount)
    else
      pre_invoice_items.joins(tariff: :billable_item).where('billable_items.billable_concept_id = ? AND subcode != "CF"', billable_concept.to_i).sum(&:amount)
    end
  end

  def total_by_concept_ff(billable_concept=1)
    pre_invoice_items.joins(tariff: :billable_item).where('billable_items.billable_concept_id = ? AND subcode = "CF"', billable_concept.to_i).sum(&:amount)
  end

  #
  # Calculated fields
  #
  def reading_1
    pre_bill.reading_1
  end

  def reading_2
    pre_bill.reading_2
  end

  def reading_1_id
    pre_bill.try(:reading_1).try(:id)
  end

  def reading_2_id
    pre_bill.try(:reading_2).try(:id)
  end

  def tax_breakdown
    pre_invoice_items.group_by{|i| i.tax_type_id}.map do |t|
      tax_id = 0
      tax = 0
      description = ''
      if !t[0].nil?
        tt = TaxType.find(t[0])
        tax_id = tt.id
        tax = tt.tax
        description = tt.description
      end
      sum_total = t[1].sum{|j| j.total}
      tax_total = sum_total * (tax/100)
      [tax, sum_total, tax_total ,t[1].count, description, tax_id]
    end
  end

  def net_tax
    tax_breakdown.sum{|t| t[2]}
  end

  def subtotal
    pre_invoice_items.reject(&:marked_for_destruction?).sum(&:amount)
  end

  def bonus
    (discount_pct / 100) * subtotal if !discount_pct.blank?
  end

  def taxable
    subtotal - bonus
  end

  def taxes
    taxes = 0
    pre_invoice_items.each do |i|
      if !i.net_tax.blank?
        taxes += i.net_tax
      end
    end
    taxes
  end

  def total
    net_tax + subtotal
  end

  def quantity
    pre_invoice_items.sum(:quantity)
  end

  private

  def calculate_and_store_totals
    self.totals = total
  end
end
