require_dependency "ag2_products/application_controller"

module Ag2Products
  class PurchasePricesController < ApplicationController
    before_filter :authenticate_user!
    load_and_authorize_resource
    $product = nil
    
    # GET /purchase_prices
    # GET /purchase_prices.json
    def index
      current_product
      @product = $product
      product = nil
      if !$product.nil?
        product = $product.id
      else
        product = params[:Products]
      end
      supplier = params[:Supplier]
  
      @search = PurchasePrice.search do
        fulltext params[:search]
        if !@product.blank?
          with :product_id, @product
        end
        if !supplier.blank?
          with :supplier_id, supplier
        end
        order_by :product_id, :asc
        order_by :supplier_id, :asc
        paginate :page => params[:page] || 1, :per_page => per_page
      end
      @purchase_prices = @search.results
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @purchase_prices }
      end
    end
  
    # GET /purchase_prices/1
    # GET /purchase_prices/1.json
    def show
      @breadcrumb = 'read'
      @product = $product
      @purchase_price = PurchasePrice.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @purchase_price }
      end
    end
  
    # GET /purchase_prices/new
    # GET /purchase_prices/new.json
    def new
      @breadcrumb = 'create'
      @product = $product
      @purchase_price = PurchasePrice.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @purchase_price }
      end
    end
  
    # GET /purchase_prices/1/edit
    def edit
      @breadcrumb = 'update'
      @product = $product
      @purchase_price = PurchasePrice.find(params[:id])
    end
  
    # POST /purchase_prices
    # POST /purchase_prices.json
    def create
      @breadcrumb = 'update'
      @product = $product
      @purchase_price = PurchasePrice.new(params[:purchase_price])
      @purchase_price.created_by = current_user.id if !current_user.nil?
  
      respond_to do |format|
        if @purchase_price.save
          format.html { redirect_to @purchase_price, notice: crud_notice('created', @purchase_price) }
          format.json { render json: @purchase_price, status: :created, location: @purchase_price }
        else
          format.html { render action: "new" }
          format.json { render json: @purchase_price.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /purchase_prices/1
    # PUT /purchase_prices/1.json
    def update
      @product = $product
      @purchase_price = PurchasePrice.find(params[:id])
      @purchase_price.updated_by = current_user.id if !current_user.nil?
  
      respond_to do |format|
        if @purchase_price.update_attributes(params[:purchase_price])
          format.html { redirect_to @purchase_price,
                        notice: (crud_notice('updated', @purchase_price) + "#{undo_link(@purchase_price)}").html_safe }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @purchase_price.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /purchase_prices/1
    # DELETE /purchase_prices/1.json
    def destroy
      @product = $product
      @purchase_price = PurchasePrice.find(params[:id])
      @purchase_price.destroy
  
      respond_to do |format|
        format.html { redirect_to purchase_prices_url,
                      notice: (crud_notice('destroyed', @purchase_price) + "#{undo_link(@purchase_price)}").html_safe }
        format.json { head :no_content }
      end
    end

    private
    
    def current_product
      if !params[:product].blank?
        $product = Product.find(params[:product])
      else
        $product = nil;
      end 
    end
  end
end
