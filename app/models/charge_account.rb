class ChargeAccount < ActiveRecord::Base
  belongs_to :project
  belongs_to :organization
  belongs_to :charge_group
  belongs_to :ledger_account
  attr_accessible :closed_at, :ledger_account_id, :name, :opened_at,
                  :project_id, :account_code, :organization_id, :charge_group_id

  has_many :budget_items
  has_many :work_orders
  has_many :work_order_items
  has_many :work_order_workers
  has_many :work_order_tools
  has_many :work_order_vehicles
  has_many :work_order_subcontractors
  has_many :work_order_types
  has_many :work_order_type_accounts
  has_many :purchase_orders
  has_many :purchase_order_items
  has_many :receipt_notes
  has_many :receipt_note_items
  has_many :offer_requests
  has_many :offer_request_items
  has_many :offers
  has_many :offers_items
  has_many :supplier_invoices
  has_many :supplier_invoice_items
  has_many :delivery_notes
  has_many :delivery_note_items
  has_many :sale_offers
  has_many :sale_offer_items
  has_many :charge_account_ledger_accounts, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :charge_account_ledger_accounts,
                                :reject_if => :all_blank,
                                :allow_destroy => true

  has_paper_trail

  validates_associated :charge_account_ledger_accounts

  validates :account_code,    :presence => true,
                              :length => { :is => 9 },
                              :format => { with: /\A\d+\Z/, message: :code_invalid },
                              :numericality => { :only_integer => true, :greater_than => 0 },
                              :uniqueness => { :scope => [:organization_id, :charge_group_id] }
  validates :name,            :presence => true
  validates :opened_at,       :presence => true
  validates :organization,    :presence => true
  validates :charge_group,    :presence => true
  validates :ledger_account,  :presence => true

  # Scopes
  scope :by_code, -> { order(:account_code) }
  #
  scope :belongs_to_project, -> project { where("project_id = ?", project).by_code }
  # generic where (eg. for Select2 from engines_controller)
  scope :g_where, -> w {
    joins("LEFT JOIN projects ON projects.id=project_id")
    .where(w)
    .by_code
  }
  scope :g_where_incomes, -> w {
    joins(:charge_group)
    .where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", 1, 3)
    .where(w)
    .by_code
  }
  scope :g_where_expenditures, -> w {
    joins(:charge_group)
    .where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", 2, 3)
    .where(w)
    .by_code
  }

  before_destroy :check_for_dependent_records

  def to_label
    "#{full_name}"
  end

  def full_name
    full_name = full_code
    if !self.name.blank?
      full_name += " " + self.name[0,40]
    end
    full_name
  end

  def full_code
    # Account code (Group code & project id & sequential number) => GGGG-PPPNN
    account_code.blank? ? "" : account_code[0..3] + '-' + account_code[4..8]
  end

  def partial_name
    name.blank? ? "" : self.name[0,30]
  end

  def partial_group_name
    charge_group.blank? ? "" : charge_group.name[0,30]
  end

  def office
    project.nil? ? nil : project.office
  end

  def company
    project.nil? ? nil : project.company
  end

  #
  # Calculated fields
  #
  def active_yes_no
    closed_at.blank? ? I18n.t(:yes_on) : I18n.t(:no_off)
  end

  def flow
    self.charge_group.flow
  end

  #
  # Class (self) user defined methods
  #
  def self.incomes(project = nil)
    if project.blank?
      joins(:charge_group).where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", 1, 3).order(:account_code)
    else
      joins(:charge_group).where("project_id = ? AND (charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", project, 1, 3).order(:account_code)
    end
  end

  def self.expenditures(project = nil)
    if project.blank?
      joins(:charge_group).where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", 2, 3).order(:account_code)
    else
      joins(:charge_group).where("project_id = ? AND (charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", project, 2, 3).order(:account_code)
    end
  end

  # def self.expenditures
  #   joins(:charge_group).where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL", 2, 3).order(:account_code)
  # end

  def self.incomes_and_expenditures
    joins(:charge_group).where("charge_groups.flow = ? AND charge_accounts.closed_at IS NULL", 3).order(:account_code)
  end

  def self.incomes_only
    joins(:charge_group).where("charge_groups.flow = ? AND charge_accounts.closed_at IS NULL", 1).order(:account_code)
  end

  def self.expenditures_only
    joins(:charge_group).where("charge_groups.flow = ? AND charge_accounts.closed_at IS NULL", 2).order(:account_code)
  end

  def self.expenditures_no_project
    joins(:charge_group).where("(charge_groups.flow = ? OR charge_groups.flow = ?) AND charge_accounts.closed_at IS NULL AND charge_accounts.project_id IS NULL", 2, 3).order(:account_code)
  end

  def self.no_project
    where("charge_accounts.closed_at IS NULL AND charge_accounts.project_id IS NULL").order(:account_code)
  end

  #
  # Records navigator
  #
  def to_first
    ChargeAccount.order("account_code").first
  end

  def to_prev
    ChargeAccount.where("account_code < ?", account_code).order("account_code").last
  end

  def to_next
    ChargeAccount.where("account_code > ?", account_code).order("account_code").first
  end

  def to_last
    ChargeAccount.order("account_code").last
  end

  searchable do
    text :account_code, :name
    string :account_code, :multiple => true   # Multiple search values accepted in one search (inverse_no_search)
    integer :project_id, :multiple => true
    integer :charge_group_id
    integer :organization_id
    string :sort_no do
      account_code
    end
  end

  private

  def check_for_dependent_records
    # Check for budget items
    if budget_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_budget_items'))
      return false
    end
    # Check for work orders
    if work_orders.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_work_orders'))
      return false
    end
    # Check for purchase orders
    if purchase_orders.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_purchase_orders'))
      return false
    end
    # Check for purchase order items
    if purchase_order_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_purchase_orders'))
      return false
    end
    # Check for receipt notes
    if receipt_notes.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_receipt_notes'))
      return false
    end
    # Check for receipt note items
    if receipt_note_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_receipt_notes'))
      return false
    end
    # Check for delivery notes
    if delivery_notes.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_delivery_notes'))
      return false
    end
    # Check for delivery note items
    if delivery_note_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_delivery_notes'))
      return false
    end
    # Check for offer requests
    if offer_requests.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_offer_requests'))
      return false
    end
    # Check for offer request items
    if offer_request_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_offer_requests'))
      return false
    end
    # Check for offers
    if offers.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_offers'))
      return false
    end
    # Check for offer items
    if offer_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_offers'))
      return false
    end
    # Check for supplier invoices
    if supplier_invoices.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_supplier_invoices'))
      return false
    end
    # Check for supplier invoice items
    if supplier_invoice_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_supplier_invoices'))
      return false
    end
    # Check for sale offers
    if sale_offers.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_sale_offers'))
      return false
    end
    # Check for sale offer items
    if sale_offer_items.count > 0
      errors.add(:base, I18n.t('activerecord.models.charge_account.check_for_sale_offers'))
      return false
    end
  end
end
