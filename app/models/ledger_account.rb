class LedgerAccount < ActiveRecord::Base
  belongs_to :accounting_group
  belongs_to :project
  belongs_to :organization
  attr_accessible :code, :name, :accounting_group_id, :project_id, :organization_id

  has_many :charge_accounts
  has_many :charge_groups
  has_many :suppliers
  has_many :clients
  
  has_paper_trail

  validates :code,              :presence => true,
                                :uniqueness => { :scope => :organization_id }
  validates :name,              :presence => true
  validates :accounting_group,  :presence => true
  validates :organization,      :presence => true

  before_destroy :check_for_dependent_records
  
  def to_label
    "#{full_name}"
  end

  def full_name
    full_name = code.blank? ? "" : code.strip
    if !self.name.blank?
      full_name += " " + self.name[0,50]
    end
    full_name
  end

  private
  
  def check_for_dependent_records
    # Check for charge accounts
    if charge_accounts.count > 0
      errors.add(:base, I18n.t('activerecord.models.ledger_account.check_for_charge_accounts'))
      return false
    end
    # Check for charge groups
    if charge_groups.count > 0
      errors.add(:base, I18n.t('activerecord.models.ledger_account.check_for_charge_groups'))
      return false
    end
    # Check for suppliers
    if suppliers.count > 0
      errors.add(:base, I18n.t('activerecord.models.ledger_account.check_for_suppliers'))
      return false
    end
    # Check for clients
    if clients.count > 0
      errors.add(:base, I18n.t('activerecord.models.ledger_account.check_for_clients'))
      return false
    end
  end
end
