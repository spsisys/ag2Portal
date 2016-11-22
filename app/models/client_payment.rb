class ClientPayment < ActiveRecord::Base
  # CONSTANTS
  CASH = 1
  BANK = 2
  FRACTIONATED = 3
  COUNTER = 4
  OTHERS = 5

  belongs_to :bill
  belongs_to :invoice
  belongs_to :payment_method
  belongs_to :client
  belongs_to :client_bank_account
  belongs_to :subscriber
  belongs_to :instalment
  belongs_to :charge_account
  attr_accessible :receipt_no, :payment_type, :payment_date, :confirmation_date, :amount, :surcharge,
                  :bill_id, :invoice_id, :client_id, :client_bank_account_id, :subscriber_id,
                  :instalment_id, :charge_account_id, :payment_method_id

  after_save :reindex_instalment
  after_destroy :reindex_instalment

  searchable do
    integer :payment_type
    text :bill_no do
      bill.bill_no
    end
    string :bill_no, :multiple => true do
      bill.bill_no
    end   # Multiple search values accepted in one search (inverse_no_search)
    integer :project_id, :multiple => true do
      bill.project_id
    end
    integer :client_id do
      bill.client_id
    end
    integer :subscriber_id do
      bill.subscriber_id
    end
    integer :entity_id do
      bill.client.entity_id
    end
    boolean :bank_account do
      bill.client.active_bank_accounts?
    end
    integer :billing_period do
      bill.reading_2.nil? ? nil : bill.reading_2.billing_period_id
    end
    integer :reading_route_id do
      bill.subscriber.nil? ? nil : bill.subscriber.reading_route_id
    end
    string :sort_no do
      bill.bill_no
    end
  end

  private

  def reindex_instalment
    Sunspot.index(instalment) if instalment
  end

end
