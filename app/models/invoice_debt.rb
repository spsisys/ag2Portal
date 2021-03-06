#
# ES: Saldos de factura (todas las facturas, originales, abonos y refacturas)
#
class InvoiceDebt < ActiveRecord::Base
  include ModelsModule

  belongs_to :invoice
  belongs_to :organization
  belongs_to :client
  belongs_to :subscriber
  belongs_to :bill
  belongs_to :project
  belongs_to :office
  belongs_to :invoice_status
  belongs_to :invoice_type
  belongs_to :invoice_operation
  attr_accessible :invoice_id, :organization_id, :bill_id,
                  :invoice_status_id, :invoice_type_id, :invoice_operation_id,
                  :client_id, :subscriber_id, :project_id, :office_id,
                  :invoice_no, :invoice_date, :payday_limit,
                  :subtotal, :taxes, :bonus, :taxable, :total, :paid, :calc_debt,
                  :totals, :receivables, :debt
  delegate :id, :to => :invoice, :allow_nil => true
  delegate :billing_period_id, :to => :invoice, :allow_nil => true
  delegate :biller_name, :to => :invoice, :allow_nil => true
  delegate :old_no_based_real_no, :to => :invoice, :allow_nil => true
  delegate :invoice_type_code, :to => :invoice, :allow_nil => true
  delegate :invoice_status_code, :to => :invoice, :allow_nil => true
  delegate :invoice_operation_code, :to => :invoice, :allow_nil => true

  has_many :debt_claim_items, through: :invoice

  # Scopes
  scope :by_no, -> { order(:invoice_no) }
  scope :by_project_bill_invoice, -> { order('invoice_current_debts.project_id, invoice_current_debts.bill_id, invoice_current_debts.invoice_id') }
  #
  scope :unpaid, -> { where("invoice_status_id = 1 AND payday_limit < ?", Date.today).by_project_bill_invoice }
  scope :unpaid_and_unclaimed, -> {
    joins('LEFT JOIN debt_claim_items ON invoice_current_debts.invoice_id=debt_claim_items.invoice_id')
    .where('debt_claim_items.invoice_id IS NULL AND invoice_current_debts.invoice_status_id = 1 AND invoice_current_debts.payday_limit < ?', Date.today)
    .by_project_bill_invoice
  }
  scope :unpaid_and_claimed, -> {
    joins(:debt_claim_items).where('invoice_current_debts.invoice_status_id = 1 AND invoice_current_debts.payday_limit < ?', Date.today)
    .by_project_bill_invoice
  }
  scope :unclaimed, -> {
    joins('LEFT JOIN debt_claim_items ON invoice_current_debts.invoice_id=debt_claim_items.invoice_id')
    .where('debt_claim_items.invoice_id IS NULL').by_project_bill_invoice
  }
  scope :claimed, -> { joins(:debt_claim_items).by_project_bill_invoice }
  #
  scope :commercial, -> { where("invoice_type_id != 1 AND invoice_type_id != 3").by_no }
  scope :service, -> { where(invoice_type_id: InvoiceType::WATER).by_no }
  scope :contracting, -> { where(invoice_type_id: InvoiceType::CONTRACT).by_no }
  #
  scope :g_where, -> w {
    joins('LEFT JOIN subscribers ON invoice_current_debts.subscriber_id = subscribers.id')
    .where(w).by_project_bill_invoice
  }
  scope :g_where_and_unclaimed, -> w {
    joins(:client, invoice: [:bill, :biller])
    .joins('LEFT JOIN billing_periods ON invoices.billing_period_id = billing_periods.id')
    .joins('LEFT JOIN debt_claim_items ON invoice_current_debts.invoice_id = debt_claim_items.invoice_id')
    .joins('LEFT JOIN invoices A ON invoice_current_debts.invoice_id = A.original_invoice_id')
    .joins('LEFT JOIN subscribers ON invoice_current_debts.subscriber_id = subscribers.id')
    .where('debt_claim_items.invoice_id IS NULL')
    .where('A.original_invoice_id IS NULL')
    .where('invoice_current_debts.invoice_status_id = 1 AND invoice_current_debts.payday_limit < ? AND invoice_current_debts.debt > 0', Date.today)
    .where(w)
    .select("invoice_current_debts.*, companies.name BILLER, billing_periods.period PERIOD,
             CONCAT(LEFT(clients.client_code,4),'-',RIGHT(clients.client_code,7)) CLIENT_CODE,
             CASE WHEN (ISNULL(clients.company) OR clients.company = '') THEN CONCAT(TRIM(clients.last_name),', ',TRIM(clients.first_name)) ELSE TRIM(clients.company) END CLIENT_NAME,
             bills.bill_no BILL_NO, invoices.invoice_no INVOICE_NO,
             CASE invoices.invoice_type_id WHEN 1 THEN 'S' WHEN 2 THEN 'T' WHEN 3 THEN 'C' WHEN 4 THEN 'L' ELSE 'O' END TYPE_CODE,
             CASE invoices.invoice_operation_id WHEN 1 THEN 'F' WHEN 2 THEN 'A' WHEN 3 THEN 'R' ELSE 'P' END OPERATION_CODE")
    .by_project_bill_invoice
  }
  scope :g_where_and_unclaimed_grouped_by_client, -> w, a, i {
    select("invoice_current_debts.client_id, SUM(invoice_current_debts.debt) AS pending_amount, COUNT(invoice_current_debts.invoice_id) AS pending_invoices")
    .joins(:client, invoice: [:bill, :biller])
    .joins('LEFT JOIN billing_periods ON invoices.billing_period_id = billing_periods.id')
    .joins('LEFT JOIN debt_claim_items ON invoice_current_debts.invoice_id = debt_claim_items.invoice_id')
    .joins('LEFT JOIN invoices A ON invoice_current_debts.invoice_id = A.original_invoice_id')
    .joins('LEFT JOIN subscribers ON invoice_current_debts.subscriber_id = subscribers.id')
    .where('debt_claim_items.invoice_id IS NULL')
    .where('A.original_invoice_id IS NULL')
    .where('invoice_current_debts.invoice_status_id = 1 AND invoice_current_debts.payday_limit < ? AND invoice_current_debts.debt > 0', Date.today)
    .where(w)
    .group('invoice_current_debts.client_id').having('pending_amount > ? OR pending_invoices > ?', a, i)
  }

  def to_label
    "#{full_name}"
  end

  #
  # Class (self) user defined methods
  #
  def self.unpaid
    where('debt > 0')
  end

  def self.existing_debt
    where('debt <> 0')
  end

  def full_name
    full_name = ""
    if !self.invoice_no.blank?
      full_name += self.invoice_no
    end
    if !self.invoice.invoice_date.blank?
      full_name += " " + formatted_date(self.invoice.invoice_date)
    end
    if !self.invoice.client.blank?
      full_name += " " + self.invoice.client.full_name
    end
    if !self.total.blank?
      full_name += ": " + formatted_number(self.total, 2)
    end
    if !self.paid.blank?
      full_name += " - " + formatted_number(self.paid, 2)
    end
    if !self.debt.blank?
      full_name += " - " + formatted_number(self.debt, 2)
    end
    full_name
  end
end
