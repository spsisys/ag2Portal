class InventoryCount < ActiveRecord::Base
  include ModelsModule
  
  belongs_to :inventory_count_type
  belongs_to :store
  belongs_to :product_family
  belongs_to :organization
  attr_accessible :count_date, :count_no, :remarks, :inventory_count_type_id,
                  :store_id, :product_family_id, :organization_id
  attr_accessible :inventory_count_items_attributes

  has_many :inventory_count_items, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :inventory_count_items,                                 
                                :reject_if => :all_blank,
                                :allow_destroy => true

  has_paper_trail

  validates_associated :inventory_count_items

  validates :count_date,            :presence => true
  validates :count_no,              :presence => true,
                                    :length => { :is => 14 },
                                    :format => { with: /\A\d+\Z/, message: :code_invalid },
                                    :uniqueness => { :scope => :organization_id }
  validates :store,                 :presence => true
  validates :inventory_count_type,  :presence => true
  validates :organization,          :presence => true

  def to_label
    "#{full_name}"
  end

  def full_name
    full_name = full_no
    if !self.count_date.blank?
      full_name += " " + formatted_date(self.count_date)
    end
    if !self.store.blank?
      full_name += " " + self.store.name
    end
    full_name
  end

  def full_no
    # Count no (Store id & year & sequential number) => SSSS-YYYY-NNNNNN
    count_no.blank? ? "" : count_no[0..3] + '-' + count_no[4..7] + '-' + count_no[8..13]
  end

  #
  # Calculated fields
  #
  def quantity
    inventory_count_items.sum("quantity")
  end

  #
  # Records navigator
  #
  def to_first
    InventoryCount.order("count_no").first
  end

  def to_prev
    InventoryCount.where("count_no < ?", count_no).order("count_no").last
  end

  def to_next
    InventoryCount.where("count_no > ?", count_no).order("count_no").first
  end

  def to_last
    InventoryCount.order("count_no").last
  end

  searchable do
    text :count_no
    string :count_no, :multiple => true    # Multiple search values accepted in one search (inverse_no_search)
    integer :payment_method_id
    integer :store_id, :multiple => true
    date :count_date
    integer :organization_id
    string :sort_no do
      count_no
    end
  end
end
