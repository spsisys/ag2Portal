class WorkerType < ActiveRecord::Base
  attr_accessible :description,
                  :created_by, :updated_by

  has_paper_trail

  validates :description, :presence => true
  
  has_many :workers
  def to_label
    "#{description.titleize}"
  end
end
