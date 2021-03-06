# encoding: utf-8

class ProductValuedStock < ActiveRecord::Base
  include ModelsModule

  belongs_to :store
  belongs_to :product_family
  belongs_to :product
  attr_accessible :store_id, :store_name, :product_family_id, :family_code, :family_name,
                  :product_id, :product_code, :main_description, :average_price,
                  :initial, :current, :current_value, :company_id, :company_name
  # Scopes
  scope :ordered_by_store_family, -> { order(:store_id, :family_code, :product_code) }
  #
  scope :belongs_to_store, -> store { where("store_id = ?", store).ordered_by_store_family }
  scope :belongs_to_family, -> family { where("product_family_id = ?", family).ordered_by_store_family }
  scope :belongs_to_product, -> product { where("product_id = ?", product).ordered_by_store_family }
  #
  scope :belongs_to_store_family, -> store, family { belongs_to_store(store).where("product_family_id = ?", family).ordered_by_store_family }
  scope :belongs_to_store_product, -> store, product { belongs_to_store(store).where("product_id = ?", product).ordered_by_store_family }
  #
  #scope :belongs_to_store_family_product, -> store, family, product { belongs_to_store(store).belongs_to_family(family).where("product_id = ?", product) }
  # for current != 0.0000
  scope :belongs_to_store_stock, -> store { where("store_id = ? AND current != ?", store,"0.0000").ordered_by_store_family }
  scope :belongs_to_family_stock, -> family { where("product_family_id = ? AND current != ?", family,"0.0000").ordered_by_store_family }
  scope :belongs_to_product_stock, -> product { where("product_id = ? AND current != ?", product,"0.0000").ordered_by_store_family }
  #
  scope :belongs_to_store_family_stock, -> store, family { belongs_to_store(store).where("product_family_id = ? AND current != ?", family,"0.0000").ordered_by_store_family }
  scope :belongs_to_store_product_stock, -> store, product { belongs_to_store(store).where("product_id = ? AND current != ?", product,"0.0000").ordered_by_store_family }

  # Aux methods for CSV
  def raw_number(_number, _d)
    formatted_number_without_delimiter(_number, _d)
  end

  def sanitize(s)
    !s.blank? ? sanitize_string(s.strip, true, true, true, false) : ''
  end

  #
  # Class (self) user defined methods
  #
  def self.to_csv(array)
    attributes = [  array[0].sanitize("Id" + " " + I18n.t("activerecord.models.company.one")),
                    array[0].sanitize(I18n.t("activerecord.models.company.one")),
                    array[0].sanitize(I18n.t("activerecord.attributes.stock.store")),
                    array[0].sanitize(I18n.t("activerecord.attributes.product.family_code")),
                    array[0].sanitize(I18n.t("activerecord.attributes.product.product_family")),
                    array[0].sanitize(I18n.t("activerecord.attributes.product.product_code")),
                    array[0].sanitize(I18n.t("activerecord.attributes.product.main_description")),
                    array[0].sanitize(I18n.t("activerecord.attributes.stock.current")),
                    array[0].sanitize(I18n.t("ag2_products.ag2_products_track.stock_report.average_price")),
                    array[0].sanitize(I18n.t("ag2_products.ag2_products_track.stock_report.total_full"))]
    col_sep = I18n.locale == :es ? ";" : ","
    CSV.generate(headers: true, col_sep: col_sep, row_sep: "\r\n") do |csv|
      csv << attributes
      array.each do |i|
        i001 = i.raw_number(i.current, 4) unless i.current.blank?
        i002 = i.raw_number(i.average_price, 4) unless i.average_price.blank?
        i003 = i.raw_number(i.current_value, 4) unless i.current_value.blank?
        csv << [  i.try(:store).try(:company).try(:id),
                  i.try(:store).try(:company).try(:name),
                  i.store_name,
                  i.try(:product_family).try(:family_code),
                  i.try(:product_family).try(:name),
                  i.try(:product).try(:full_code),
                  i.try(:product).try(:main_description),
                  i001,
                  i002,
                  i003]
      end
    end
  end
end
