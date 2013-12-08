class PurchasePrice < ActiveRecord::Base
  belongs_to :product
  belongs_to :supplier
  belongs_to :measure
  attr_accessible :code, :factor, :favorite, :price, :product_id, :supplier_id, :measure_id

  has_paper_trail

  validates :product,  :presence => true
  validates :supplier, :presence => true
  validates :measure,  :presence => true
  validates :code,     :presence => true

  searchable do
    text :code
    integer :product_id
    integer :supplier_id
    integer :measure_id
    integer :id
    string :code
  end
end
