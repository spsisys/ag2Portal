class OfferRequestSupplier < ActiveRecord::Base
  belongs_to :offer_request
  belongs_to :supplier
  attr_accessible :offer_request_id, :supplier_id

  has_paper_trail

  validates :offer_request, :presence => true
  validates :supplier,      :presence => true
end
