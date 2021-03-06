class WorkOrderArea < ActiveRecord::Base
  belongs_to :organization
  attr_accessible :name, :organization_id

  has_many :work_orders
  has_many :work_order_types

  has_paper_trail

  validates :name,          :presence => true
  validates :organization,  :presence => true

  # Scopes
  scope :by_name, -> { order(:name) }
  #
  scope :belongs_to_organization, -> organization { where("organization_id = ?", organization).by_name }

  before_destroy :check_for_dependent_records

  def short_name
    name[0,20]
  end

  private

  def check_for_dependent_records
    # Check for work orders
    if work_orders.count > 0
      errors.add(:base, I18n.t('activerecord.models.work_order_area.check_for_work_orders'))
      return false
    end
  end
end
