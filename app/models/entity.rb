class Entity < ActiveRecord::Base
  belongs_to :street_type
  belongs_to :zipcode
  belongs_to :town
  belongs_to :province
  belongs_to :region
  belongs_to :country
  belongs_to :entity_type
  belongs_to :organization
  attr_accessible :building, :cellular, :company, :email, :extension, :fax, :first_name, :fiscal_id,
                  :floor, :floor_office, :last_name, :phone, :street_name, :street_number, :town,
                  :entity_type_id, :street_type_id, :zipcode_id, :town_id, :province_id, :region_id, :country_id,
                  :created_by, :updated_by, :organization_id

  has_one :supplier
  has_one :client

  has_paper_trail

  validates :first_name,   :presence => true, :if => "company.blank?"
  validates :last_name,    :presence => true, :if => "company.blank?"
  validates :fiscal_id,    :presence => true,
                           :length => { :minimum => 9 },
                           :uniqueness => { :scope => :organization_id }
  validates :street_type,  :presence => true
  validates :zipcode,      :presence => true
  validates :town,         :presence => true
  validates :province,     :presence => true
  validates :region,       :presence => true
  validates :country,      :presence => true
  validates :entity_type,  :presence => true
  #validates :organization, :presence => true

  before_validation :fields_to_uppercase
  before_destroy :check_for_dependent_records
  after_update :update_dependent_records

  def fields_to_uppercase
    if !self.fiscal_id.blank?
      self[:fiscal_id].upcase!
    end
    true
  end

  def full_name
    full_name = ""
    if !self.last_name.blank?
      full_name += self.last_name
    end
    if !self.first_name.blank?
      full_name += ", " + self.first_name
    end
    full_name
  end

  def to_label
    if !self.last_name.blank? && !self.first_name.blank?
      "#{fiscal_id}: #{last_name}, #{first_name}"
    else
      "#{fiscal_id}: #{company}"
    end
  end

  #
  # Records navigator
  #
  def to_first
    Entity.order("fiscal_id").first
  end

  def to_prev
    Entity.where("fiscal_id < ?", fiscal_id).order("fiscal_id").last
  end

  def to_next
    Entity.where("fiscal_id > ?", fiscal_id).order("fiscal_id").first
  end

  def to_last
    Entity.order("fiscal_id").last
  end

  searchable do
    text :first_name, :last_name, :company, :fiscal_id, :cellular, :phone, :email, :street_name
    string :company
    string :last_name
    string :first_name
    string :fiscal_id
    integer :organization_id
  end

  private

  def check_for_dependent_records
    # Check for suppliers
    if !supplier.nil?
      errors.add(:base, I18n.t('activerecord.models.entity.check_for_suppliers'))
      return false
    end
    # Check for clients
    if !client.nil?
      errors.add(:base, I18n.t('activerecord.models.entity.check_for_clients'))
      return false
    end
  end

  def update_dependent_records
    # Update linked supplier
    if !supplier.nil?
      if entity_type_id < 2
        supplier.name = full_name
      else
        supplier.name = company
      end
      supplier.street_type_id = street_type_id
      supplier.street_name = street_name
      supplier.street_number = street_number
      supplier.building = building
      supplier.floor = floor
      supplier.floor_office = floor_office
      supplier.zipcode_id = zipcode_id
      supplier.town_id = town_id
      supplier.province_id = province_id
      supplier.region_id = region_id
      supplier.country_id = country_id
      supplier.phone = phone
      supplier.fax = fax
      supplier.cellular = cellular
      supplier.email = email
      if !supplier.save
        errors.add(:base, I18n.t('activerecord.models.entity.update_suppliers'))
      end
    end
    
    # Update linked client
    if !client.nil?
      if entity_type_id < 2
        client.name = full_name
      else
        client.name = company
      end
      client.street_type_id = street_type_id
      client.street_name = street_name
      client.street_number = street_number
      client.building = building
      client.floor = floor
      client.floor_office = floor_office
      client.zipcode_id = zipcode_id
      client.town_id = town_id
      client.province_id = province_id
      client.region_id = region_id
      client.country_id = country_id
      client.phone = phone
      client.fax = fax
      client.cellular = cellular
      client.email = email
      if !client.save
        errors.add(:base, I18n.t('activerecord.models.entity.update_clients'))
      end
    end
  end
end
