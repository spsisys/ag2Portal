class PurchasePrice < ActiveRecord::Base
  belongs_to :product
  belongs_to :supplier
  belongs_to :measure
  attr_accessible :code, :factor, :favorite, :price, :product_id, :supplier_id, :measure_id

  has_paper_trail

  validates :product_id,  :presence => true
  validates :supplier_id, :presence => true
  validates :measure_id,  :presence => true
  validates :code,        :presence => true

  searchable do
    text :code
    integer :product_id
    integer :supplier_id
    integer :measure_id
    integer :id
    decimal :price
    string :code
  end
end
