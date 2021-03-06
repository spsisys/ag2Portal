class Organization < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_organizations
  attr_accessible :name, :hd_email

  # admin
  has_many :companies
  has_many :offices, through: :companies
  has_many :entities
  has_many :ledger_accounts
  has_many :zones
  # directory
  has_many :corp_contacts
  has_many :shared_contacts
  # finance
  # gest
  has_many :clients
  has_many :sale_offers
  has_many :meters
  has_many :subscribers, through: :offices
  has_many :service_points
  has_many :bills
  has_many :invoices
  has_many :invoice_debts
  has_many :invoice_current_debts
  has_many :invoice_bills
  has_many :invoice_credits
  has_many :invoice_rebills
  has_many :instalment_plans
  has_many :contract_templates
  # helpdesk
  has_many :technicians
  has_many :tickets
  # human
  has_many :workers
  has_many :collective_agreements
  has_many :contract_types
  has_many :degree_types
  has_many :departments
  has_many :insurances
  has_many :professional_groups
  has_many :salary_concepts
  # logistics
  has_many :products
  has_many :product_families
  has_many :stores
  has_many :delivery_notes
  has_many :receipt_notes
  has_many :inventory_counts
  has_many :inventory_transfers
  # purchase
  has_many :suppliers
  has_many :payment_methods
  has_many :offer_requests
  has_many :offers
  has_many :purchase_orders
  has_many :supplier_invoices
  has_many :supplier_payments
  has_many :supplier_invoice_debts
  # tech
  has_many :projects
  has_many :work_orders
  has_many :charge_accounts
  has_many :charge_groups
  has_many :work_order_areas
  has_many :work_order_labors
  has_many :work_order_types
  has_many :budget_headings
  has_many :budget_periods
  has_many :budgets
  has_many :vehicles
  has_many :tools
  has_many :ratios
  has_many :ratio_groups
  has_many :infrastructure_types
  has_many :infrastructures

  has_paper_trail

  validates :name,  :presence => true

  before_validation :fields_to_uppercase
  before_destroy :check_for_dependent_records

  def fields_to_uppercase
    if !self.name.blank?
      self[:name].upcase!
    end
  end

  private

  def check_for_dependent_records
    # Check for companies
    if companies.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_companies'))
      return false
    end
    # Check for entities
    if entities.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_entities'))
      return false
    end
    # Check for clients
    if clients.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_clients'))
      return false
    end
    # Check for suppliers
    if suppliers.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_suppliers'))
      return false
    end
    # Check for payment methods
    if payment_methods.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_payment_methods'))
      return false
    end
    # Check for workers
    if workers.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_workers'))
      return false
    end
    # Check for technicians
    if technicians.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_technicians'))
      return false
    end
    # Check for corporate contacts
    if corp_contacts.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_corp_contacts'))
      return false
    end
    # Check for products
    if products.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_products'))
      return false
    end
    # Check for stores
    if stores.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_stores'))
      return false
    end
    # Check for vehicles
    if vehicles.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_vehicles'))
      return false
    end
    # Check for tools
    if tools.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_tools'))
      return false
    end
    # Check for ratios
    if ratios.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_ratios'))
      return false
    end
    # Check for ratio groups
    if ratio_groups.count > 0
      errors.add(:base, I18n.t('activerecord.models.organization.check_for_ratio_groups'))
      return false
    end
  end
end
