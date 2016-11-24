class Center < ActiveRecord::Base
  belongs_to :town
  attr_accessible :active, :name, :town_id

  has_many :subscribers

  has_paper_trail

  validates :town,        :presence => true
  validates :name,        :presence => true

  # Scopes
  scope :by_town, -> { order(:town_id, :name) }

  before_destroy :check_for_dependent_records

  def to_label
    "#{name} (#{town.name})"
  end

  private

  # Before destroy
  def check_for_dependent_records
    # Check for subscribers
    if subscribers.count > 0
      errors.add(:base, I18n.t('activerecord.models.center.check_for_subscribers'))
      return false
    end
  end
end
