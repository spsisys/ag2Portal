class ReadingRoute < ActiveRecord::Base
  belongs_to :project
  belongs_to :office

  alias_attribute :route_code, :routing_code
  attr_accessible :name, :routing_code, :project_id, :office_id, :route_code

  has_many :subscribers
  has_many :pre_readings
  has_many :readings
  has_many :service_points
  has_many :water_supply_contracts

  has_paper_trail

  # validates :route_code,  :presence => true
  validate :route_code,   :presence => true, :before => :create
  validates :office_id,   :presence => true

  # Scopes
  scope :by_code, -> { order(:routing_code) }
  #
  scope :by_office, -> o { where(office_id: o).by_code }
  scope :for_dropdown_by_office, -> office {
    select("id, CONCAT(CONCAT(SUBSTR(routing_code,1,4), '-', SUBSTR(routing_code,5,6)), ' ', name) to_label_")
    .where(office_id: office)
    .by_code
  }
  scope :for_dropdown, -> {
    select("id, CONCAT(CONCAT(SUBSTR(routing_code,1,4), '-', SUBSTR(routing_code,5,6)), ' ', name) to_label_")
    .by_code
  }

  # Callbacks
  before_create :assign_code_office

  # Methods
  def assign_code_office
    self.routing_code = next_rr(office_id || project.office_id)
  end

  def to_label
    "#{full_code} #{name}"
  end

  def full_code
    # Reading route code (Office id & sequential number) => OOOO-NNNNNN
    routing_code.blank? ? "" : routing_code[0..3] + '-' + routing_code[4..9]
  end

  #
  # Class (self) user defined methods
  #
  def self.dropdown(office=nil)
    if office.present?
      self.for_dropdown_by_office(office)
    else
      self.for_dropdown
    end
  end

  private

  # This method has been changed because the old code was a mess
  def next_rr(office)
    code = ''
    office = office.to_s if office.is_a? Fixnum
    office = office.rjust(4, '0')
    last_no = ReadingRoute.where("routing_code LIKE ?", "#{office}%").order(:routing_code).maximum(:routing_code)
    if last_no.nil?
      code = office + '000001'
    else
      last_no = last_no[4..9].to_i + 1
      code = office +  last_no.to_s.rjust(6, '0')
    end
    code
  end
end
