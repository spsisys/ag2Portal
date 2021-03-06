require_dependency "ag2_purchase/application_controller"
require 'will_paginate/array'

module Ag2Purchase
  class OfferRequestsController < ApplicationController
    include ActionView::Helpers::NumberHelper
    before_filter :authenticate_user!
    load_and_authorize_resource
    skip_load_and_authorize_resource :only => [:or_remove_filters,
                                               :or_restore_filters,
                                               :or_update_description_prices_from_product_store,
                                               :or_update_description_prices_from_product,
                                               :or_update_charge_account_from_order,
                                               :or_update_charge_account_from_project,
                                               :or_update_amount_from_price_or_quantity,
                                               :or_format_numbers,
                                               :or_totals,
                                               :or_current_stock,
                                               :or_update_project_textfields_from_organization,
                                               :or_update_product_select_from_organization,
                                               :or_generate_no,
                                               :or_product_stock,
                                               :or_product_all_stocks,
                                               :or_approve_offer,
                                               :or_disapprove_offer,
                                               :offer_request_form,
                                               :offer_request_form_no_prices,
                                               :send_offer_request_form,
                                               :or_generate_request,
                                               :offer_request_view_report]
    # Helper methods for
    # => index filters
    helper_method :or_remove_filters, :or_restore_filters

    # Calculate and format totals properly
    def or_totals
      qty = params[:qty].to_f / 10000
      amount = params[:amount].to_f / 10000
      tax = params[:tax].to_f / 10000
      discount_p = params[:discount_p].to_f / 100
      tbl = params[:tbl]
      # Bonus
      discount = discount_p != 0 ? amount * (discount_p / 100) : 0
      # Taxable
      taxable = amount - discount
      # Taxes
      tax = tax - (tax * (discount_p / 100)) if discount_p != 0
      # Total
      total = taxable + tax
      # Format output values
      qty = number_with_precision(qty.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      discount = number_with_precision(discount.round(4), precision: 4)
      taxable = number_with_precision(taxable.round(4), precision: 4)
      total = number_with_precision(total.round(4), precision: 4)
      # Setup JSON hash
      @json_data = { "qty" => qty.to_s, "amount" => amount.to_s, "tax" => tax.to_s,
                     "discount" => discount.to_s, "taxable" => taxable.to_s, "total" => total.to_s, "tbl" => tbl.to_s }
      render json: @json_data
    end

    # Update description and prices text fields at view from product & store selects
    def or_update_description_prices_from_product_store
      product = params[:product]
      store = params[:store]
      tbl = params[:tbl]
      description = ""
      qty = 0
      price = 0
      amount = 0
      tax_type_id = 0
      tax_type_tax = 0
      tax = 0
      current_stock = 0
      product_stock = 0
      if product != '0'
        @product = Product.find(product)
        #@prices = @product.purchase_prices
        # Assignment
        description = @product.main_description[0,40]
        qty = params[:qty].to_f / 10000
        price = @product.reference_price
        amount = qty * price
        tax_type_id = @product.tax_type.id
        tax_type_tax = @product.tax_type.tax
        tax = amount * (tax_type_tax / 100)
        product_stock = @product.not_jit_stock
        if store != 0
          current_stock = Stock.find_by_product_and_store(product, store).current rescue 0
        end
      end
      # Format numbers
      price = number_with_precision(price.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      current_stock = number_with_precision(current_stock.round(4), precision: 4)
      product_stock = number_with_precision(product_stock.round(4), precision: 4)
      # Setup JSON
      @json_data = { "description" => description, "price" => price.to_s, "amount" => amount.to_s,
                     "tax" => tax.to_s, "type" => tax_type_id, "stock" => current_stock.to_s,
                     "product_stock" => product_stock.to_s, "tbl" => tbl.to_s }
      render json: @json_data
    end

    # Update description and prices text fields at view from product select
    def or_update_description_prices_from_product
      product = params[:product]
      description = ""
      qty = 0
      price = 0
      amount = 0
      tax_type_id = 0
      tax_type_tax = 0
      tax = 0
      if product != '0'
        @product = Product.find(product)
        @prices = @product.purchase_prices
        # Assignment
        description = @product.main_description[0,40]
        qty = params[:qty].to_f / 10000
        price = @product.reference_price
        amount = qty * price
        tax_type_id = @product.tax_type.id
        tax_type_tax = @product.tax_type.tax
        tax = amount * (tax_type_tax / 100)
      end
      # Format numbers
      price = number_with_precision(price.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      # Setup JSON
      @json_data = { "description" => description, "price" => price.to_s, "amount" => amount.to_s,
                     "tax" => tax.to_s, "type" => tax_type_id }
      render json: @json_data
    end

    # Update amount and tax text fields at view (quantity or price changed)
    def or_update_amount_from_price_or_quantity
      price = params[:price].to_f / 10000
      qty = params[:qty].to_f / 10000
      tax_type = params[:tax_type].to_i
      #discount_p = params[:discount_p].to_f / 100
      #discount = params[:discount].to_f / 10000
      product = params[:product]
      tbl = params[:tbl]
      if tax_type.blank? || tax_type == "0"
        if !product.blank? && product != "0"
          tax_type = Product.find(product).tax_type.id
        else
          tax_type = TaxType.where('expiration IS NULL').order('id').first.id
        end
      end
      tax = TaxType.find(tax_type).tax
      #if discount_p > 0
      #  discount = price * (discount_p / 100)
      #end
      #amount = qty * (price - discount)
      amount = qty * price
      tax = amount * (tax / 100)
      qty = number_with_precision(qty.round(4), precision: 4)
      price = number_with_precision(price.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      #discount_p = number_with_precision(discount_p.round(2), precision: 2)
      #discount = number_with_precision(discount.round(4), precision: 4)
      @json_data = { "quantity" => qty.to_s, "price" => price.to_s, "amount" => amount.to_s, "tax" => tax.to_s, "tbl" => tbl.to_s }
      #               "discountp" => discount_p.to_s, "discount" => discount.to_s }

      respond_to do |format|
        format.html # or_update_amount_from_price_or_quantity.html.erb does not exist! JSON only
        format.json { render json: @json_data }
      end
    end

    # Update charge account and store text fields at view from work order select
    def or_update_charge_account_from_order
      order = params[:order]
      projects = projects_dropdown
      charge_account_id = 0
      store_id = 0
      if order != '0'
        @order = WorkOrder.find(order)
        @project = @order.project
        @charge_account = @order.charge_account
        charge_account_id = @charge_account.id rescue 0
        @store = @order.store
        store_id = @store.id rescue 0
        if @charge_account.blank?
          @charge_account = @project.blank? ? projects_charge_accounts(projects) : charge_accounts_dropdown_edit(@project)
        end
        if @store.blank?
          @store = project_stores(@project)
        end
      else
        @charge_account = projects_charge_accounts(projects)
        @store = stores_dropdown
      end
      @json_data = { "charge_account" => @charge_account, "store" => @store,
                     "charge_account_id" => charge_account_id, "store_id" => store_id }
      render json: @json_data
    end

    # Update work order, charge account and store text fields at view from project select
    def or_update_charge_account_from_project
      project = params[:order]
      projects = projects_dropdown
      if project != '0'
        @project = Project.find(project)
        @work_order = @project.blank? ? work_orders_dropdown : @project.work_orders.order(:order_no)
          @charge_account = @project.blank? ? projects_charge_accounts(projects) : charge_accounts_dropdown_edit(@project)
        @store = project_stores(@project)
      else
        @work_order = work_orders_dropdown
        @charge_account = projects_charge_accounts(projects)
        @store = stores_dropdown
      end
      # Work orders array
      @orders_dropdown = orders_array(@work_order)
      # Setup JSON
      @json_data = { "work_order" => @orders_dropdown, "charge_account" => @charge_account, "store" => @store }
      render json: @json_data
    end

    # Format numbers properly
    def or_format_number
      num = params[:num].to_f / 100
      num = number_with_precision(num.round(2), precision: 2)
      @json_data = { "num" => num.to_s }
      render json: @json_data
    end

    # Update current stock text field at view from store select
    def or_current_stock
      product = params[:product]
      store = params[:store]
      current_stock = 0
      if product != '0' && store != '0'
        current_stock = Stock.find_by_product_and_store(product, store).current rescue 0
      end
      # Format numbers
      current_stock = number_with_precision(current_stock.round(4), precision: 4)
      # Setup JSON
      @json_data = { "stock" => current_stock.to_s }
      render json: @json_data
    end

    # Update project text and other fields at view from organization select
    def or_update_project_textfields_from_organization
      organization = params[:org]
      if organization != '0'
        @organization = Organization.find(organization)
        @suppliers = @organization.blank? ? suppliers_dropdown : @organization.suppliers.order(:supplier_code)
        @projects = @organization.blank? ? projects_dropdown : @organization.projects.order(:project_code)
        @work_orders = @organization.blank? ? work_orders_dropdown : @organization.work_orders.order(:order_no)
        @charge_accounts = @organization.blank? ? charge_accounts_dropdown : @organization.charge_accounts.expenditures
        @stores = @organization.blank? ? stores_dropdown : @organization.stores.order(:name)
        @payment_methods = @organization.blank? ? payment_methods_dropdown : payment_payment_methods(@organization.id)
        @products = @organization.blank? ? products_dropdown : @organization.products.order(:product_code)
      else
        @suppliers = suppliers_dropdown
        @projects = projects_dropdown
        @work_orders = work_orders_dropdown
        @charge_accounts = charge_accounts_dropdown
        @stores = stores_dropdown
        @payment_methods = payment_methods_dropdown
        @products = products_dropdown
      end
      # Work orders array
      @orders_dropdown = orders_array(@work_orders)
      # Products array
      @products_dropdown = products_array(@products)
      # Setup JSON
      @json_data = { "supplier" => @suppliers, "project" => @projects, "work_order" => @orders_dropdown,
                     "charge_account" => @charge_accounts, "store" => @stores,
                     "payment_method" => @payment_methods, "product" => @products_dropdown }
      render json: @json_data
    end

    # Update product select at view from organization select
    def or_update_product_select_from_organization
      organization = params[:org]
      if organization != '0'
        @organization = Organization.find(organization)
        @products = @organization.blank? ? products_dropdown : @organization.products.order(:product_code)
      else
        @products = products_dropdown
      end
      # Products array
      @products_dropdown = products_array(@products)
      # Setup JSON
      @json_data = { "product" => @products_dropdown }
      render json: @json_data
    end

    # Update order number at view (generate_code_btn)
    def or_generate_no
      project = params[:project]

      # Builds no, if possible
      code = project == '$' ? '$err' : or_next_no(project)
      @json_data = { "code" => code }
      render json: @json_data
    end

    # Product stock by store
    def or_product_stock
      product = params[:product]
      qty = params[:qty].to_f / 10000
      store = params[:store]
      stocks = nil
      if product != '0' && store != 0
        stocks = Stock.find_by_product_and_not_store_and_positive(product, store)
      end
      render json: stocks, include: :store
    end

    # infoButton
    def or_product_all_stocks
      product = params[:product]
      stocks = nil
      if product != '0'
        stocks = Stock.find_by_product_all_stocks(product)
      end
      render json: stocks, include: :store
    end

    # Approve offer
    def or_approve_offer
      _offer = params[:offer]
      _offer_request = params[:offer_request]
      code = '$err'
      _approver_id = nil
      _approver = nil
      _approval_date = nil

      offer_request = OfferRequest.find(_offer_request)
      if !offer_request.nil?
        if offer_request.approved_offer_id.blank?
          # Can approve offer
          offer = Offer.find(_offer)
          if !offer.nil? && !current_user.nil?
            # Attempt approve
            _approver_id = current_user.id
            _approval_date = DateTime.now
            offer.approver_id = _approver_id
            offer.approval_date = _approval_date
            if offer.save
              offer_request.approved_offer_id = _offer
              offer_request.approver_id = _approver_id
              offer_request.approval_date = _approval_date
              if offer_request.save
                # Success
                code = '$ok'
              else
                # Can't save offer request
                code = '$write'
              end
            else
              # Can't save offer
              code = '$write'
            end
          else
            # Offer not found or user not logged in
            code = '$err'
          end
        else
          # There is an offer already approved
          code = '$warn'
        end
      else
        # Offer request not found
        code = '$err'
      end
      # Approver data
      if !_approver_id.nil?
        _approver = User.find(_approver_id).email
      end
      # Approval date
      if !_approval_date.nil?
        _approval_date = formatted_timestamp(_approval_date)
      end

      # Success
      # Send approval notification to creator
      if code == '$ok'
        send_approve_email(offer)
      end

      @json_data = { "code" => code, "approver" => _approver, "approval_date" => _approval_date }
      render json: @json_data
    end

    # Disapprove offer
    def or_disapprove_offer
      _offer = params[:offer]
      _offer_request = params[:offer_request]
      code = '$err'

      offer_request = OfferRequest.find(_offer_request)
      if !offer_request.nil?
        if !offer_request.approved_offer_id.blank?
          # Can disapprove offer
          offer = Offer.find(_offer)
          if !offer.nil?
            # Attempt disapprove
            offer.approver_id = nil
            offer.approval_date = nil
            if offer.save
              offer_request.approved_offer_id = nil
              offer_request.approver_id = nil
              offer_request.approval_date = nil
              if offer_request.save
                # Success
                code = '$ok'
              else
                # Can't save offer request
                code = '$write'
              end
            else
              # Can't save offer
              code = '$write'
            end
          else
            # Offer not found
            code = '$err'
          end
        else
          # There isn't previous offer approved
          code = '$warn'
        end
      else
        # Offer request not found
        code = '$err'
      end
      @json_data = { "code" => code }
      render json: @json_data
    end

    # Email Report (jQuery)
    def send_offer_request_form
      code = send_email(params[:id])
      message = code == '$err' ? t(:send_error) : t(:send_ok)
      @json_data = { "code" => code, "message" => message }
      render json: @json_data
    end

    # Generate new request using designated suppliers & families
    def or_generate_request
      suppliers = params[:supplier]
      families = params[:family]
      offer_date = params[:offer_date]  # YYYYMMDD
      project = params[:project]
      store = params[:store]
      account = params[:account]
      payment = params[:payment]
      request = nil
      request_item = nil
      code = ''

      # Params data to array
      suppliers = suppliers.split(",")
      families = families.split(",")

      # Format offer_date
      offer_date = (offer_date[0..3] + '-' + offer_date[4..5] + '-' + offer_date[6..7]).to_date

      # Generate new offer request
      if (!suppliers.empty? && !families.empty?) && (project != '$' && project != '' && project != '0')
        # Generate new offer request no.
        code = or_next_no(project)
        if code != '$err'
          # Try create request
          request = OfferRequest.new
          request.request_no = code
          request.request_date = offer_date
          request.payment_method_id = payment
          request.project_id = project
          request.created_by = current_user.id if !current_user.nil?
          request.store_id = store
          request.charge_account_id = account
          request.organization_id = Project.find(project).organization_id
          if request.save
            # Loop thru families
            families.each do |f|
              family = ProductFamily.find(f) rescue nil
              if !family.nil?
                family.products.actives.each do |p|
                  # Try to save request offer item
                  request_item = OfferRequestItem.new
                  request_item.offer_request_id = request.id
                  request_item.product_id = p.id
                  request_item.description = p.main_description
                  request_item.quantity = 1
                  request_item.price = p.reference_price
                  request_item.tax_type_id = p.tax_type_id
                  request_item.created_by = current_user.id if !current_user.nil?
                  request_item.project_id = project
                  request_item.store_id = store
                  request_item.charge_account_id = account
                  if !request_item.save
                    # Can't save item (exit)
                    code = '$write'
                    break
                  end   # !request_item.save?
                end   # family.products.each do |p|
              end   # !family.nil?
            end   # families.each do |f|
            # Update totals
            request.update_column(:totals, OfferRequest.find(request.id).total)
            # Loop thru suppliers
            suppliers.each do |s|
              supplier = Supplier.find(s) rescue nil
              if !supplier.nil?
                # Try to save request offer supplier
                request_item = OfferRequestSupplier.new
                request_item.offer_request_id = request.id
                request_item.supplier_id = supplier.id
                if !request_item.save
                  # Can't save supplier (exit)
                  code = '$write'
                  break
                end   # !request_item.save?
              end   # !supplier.nil?
            end   # suppliers.each do |s|
          else
            # Can't save request
            code = '$write'
          end   # request.save
        end   # code != '$err' (else request_no invalid)
      else
        # Suppliers or Families empty or Project not found
        code = '$err'
      end   # !suppliers.empty? && !families.empty?

      if code != '$err' && code != '$write'
        code = I18n.t("ag2_purchase.offer_requests.generate_request_ok", var: request.full_no)
      end
      @json_data = { "code" => code }
      render json: @json_data
    end

    #
    # Default Methods
    #
    # GET /offer_requests
    # GET /offer_requests.json
    def index
      manage_filter_state
      no = params[:No]
      supplier = params[:Supplier]
      project = params[:Project]
      order = params[:Order]
      account = params[:Account]
      # OCO
      init_oco if !session[:organization]
      # Initialize select_tags
      @supplier = !supplier.blank? ? Supplier.find(supplier).full_name : " "
      @project = !project.blank? ? Project.find(project).full_name : " "
      @work_order = !order.blank? ? WorkOrder.find(order).full_name : " "
      @charge_account = !account.blank? ? ChargeAccount.find(account).full_name : " "

      # Arrays for search
      if !supplier.blank?   # Offer requests that include current supplier
        @request_suppliers = OfferRequestSupplier.group(:offer_request_id).where(supplier_id: supplier)
      else
        @request_suppliers = OfferRequestSupplier.group(:offer_request_id)
      end
      @projects = projects_dropdown if @projects.nil?
      current_suppliers = @request_suppliers.blank? ? [0] : current_suppliers_for_index(@request_suppliers)
      current_projects = @projects.blank? ? [0] : current_projects_for_index(@projects)
      # If inverse no search is required
      no = !no.blank? && no[0] == '%' ? inverse_no_search(no) : no

      # Auto generate request
      @suppliers = suppliers_dropdown if @suppliers.nil?
      @current_projects = Project.where(id: current_projects) if @current_projects.nil?
      @search_projects = @current_projects.map{ |p| p.id }.map(&:inspect).join(',')
      @families = families_dropdown if @families.nil?
      # @charge_accounts = projects_charge_accounts(@current_projects) if @charge_accounts.nil?
      @stores = projects_stores(@current_projects) if @stores.nil?
      @payment_methods = payment_methods_dropdown if @payment_methods.nil?

      @search = OfferRequest.search do
        with :project_id, current_projects
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !no.blank?
          if no.class == Array
            with :request_no, no
          else
            with(:request_no).starting_with(no)
          end
        end
        if !supplier.blank?
          with :id, current_suppliers
        end
        if !project.blank?
          with :project_id, project
        end
        if !order.blank?
          with :work_order_id, order
        end
        data_accessor_for(OfferRequest).include = [{approved_offer: :supplier}]
        order_by :sort_no, :desc
        paginate :page => params[:page] || 1, :per_page => per_page
      end
      @offer_requests = @search.results

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @offer_requests }
        format.js
      end
    end

    # GET /offer_requests/1
    # GET /offer_requests/1.json
    def show
      @breadcrumb = 'read'
      @offer_request = OfferRequest.find(params[:id])
      @items = @offer_request.offer_request_items.paginate(:page => params[:page], :per_page => per_page).order('id')
      @suppliers = @offer_request.offer_request_suppliers.paginate(:page => params[:page], :per_page => per_page).order('id')
      @offers = sort_offers_by_total(@offer_request).paginate(:page => params[:page], :per_page => per_page)
      #@offers = @offer_request.offers.paginate(:page => params[:page], :per_page => per_page).order('id')
      # Offer Approvers
      @is_approver = false
      if @offers.count > 0
        offer = @offers.first
        @is_approver = company_approver(offer, offer.project.company, current_user.id) ||
                       office_approver(offer, offer.project.office, current_user.id) ||
                       (current_user.has_role? :Approver)
      end

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @offer_request }
      end
    end

    # GET /offer_requests/new
    # GET /offer_requests/new.json
    def new
      @breadcrumb = 'create'
      @offer_request = OfferRequest.new
      @projects = projects_dropdown
      @work_orders = work_orders_dropdown
      @charge_accounts = projects_charge_accounts(@projects)
      @stores = stores_dropdown
      @suppliers = suppliers_dropdown
      @payment_methods = payment_methods_dropdown
      # @products = products_dropdown

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @offer_request }
      end
    end

    # GET /offer_requests/1/edit
    def edit
      @breadcrumb = 'update'
      @offer_request = OfferRequest.find(params[:id])
      @projects = projects_dropdown_edit(@offer_request.project)
      @work_orders = @offer_request.project.blank? ? work_orders_dropdown : @offer_request.project.work_orders.by_no
      @charge_accounts = work_order_charge_account(@offer_request)
      @stores = work_order_store(@offer_request)
      @suppliers = @offer_request.organization.blank? ? suppliers_dropdown : @offer_request.organization.suppliers.by_code
      @payment_methods = @offer_request.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@offer_request.organization_id)
      # @products = @offer_request.organization.blank? ? products_dropdown : @offer_request.organization.products.by_code
    end

    # POST /offer_requests
    # POST /offer_requests.json
    def create
      @breadcrumb = 'create'
      @offer_request = OfferRequest.new(params[:offer_request])
      @offer_request.created_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @offer_request.save
          format.html { redirect_to @offer_request, notice: crud_notice('created', @offer_request) }
          format.json { render json: @offer_request, status: :created, location: @offer_request }
        else
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @suppliers = suppliers_dropdown
          @payment_methods = payment_methods_dropdown
          # @products = products_dropdown
          format.html { render action: "new" }
          format.json { render json: @offer_request.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /offer_requests/1
    # PUT /offer_requests/1.json
    def update
      @breadcrumb = 'update'
      @offer_request = OfferRequest.find(params[:id])

      items_changed = false
      if params[:offer_request][:offer_request_suppliers_attributes]
        params[:offer_request][:offer_request_suppliers_attributes].values.each do |new_item|
          current_item = OfferRequestSupplier.find(new_item[:id]) rescue nil
          if ((current_item.nil?) || (new_item[:_destroy] != "false") ||
             ((current_item.supplier_id.to_i != new_item[:supplier_id].to_i)))
            items_changed = true
            break
          end
        end
      end
      if !items_changed && params[:offer_request][:offer_request_items_attributes]
        params[:offer_request][:offer_request_items_attributes].values.each do |new_item|
          current_item = OfferRequestItem.find(new_item[:id]) rescue nil
          if ((current_item.nil?) || (new_item[:_destroy] != "false") ||
             ((current_item.product_id.to_i != new_item[:product_id].to_i) ||
              (current_item.description != new_item[:description]) ||
              (current_item.quantity.to_f != new_item[:quantity].to_f) ||
              (current_item.price.to_f != new_item[:price].to_f) ||
              (current_item.tax_type_id.to_i != new_item[:tax_type_id].to_i) ||
              (current_item.project_id.to_i != new_item[:project_id].to_i) ||
              (current_item.work_order_id.to_i != new_item[:work_order_id].to_i) ||
              (current_item.charge_account_id.to_i != new_item[:charge_account_id].to_i) ||
              (current_item.store_id.to_i != new_item[:store_id].to_i)))
            items_changed = true
            break
          end
        end
      end
      master_changed = false
      if ((params[:offer_request][:organization_id].to_i != @offer_request.organization_id.to_i) ||
          (params[:offer_request][:project_id].to_i != @offer_request.project_id.to_i) ||
          (params[:offer_request][:request_no].to_s != @offer_request.request_no) ||
          (params[:offer_request][:request_date].to_date != @offer_request.request_date) ||
          (params[:offer_request][:deadline_date].to_date != @offer_request.deadline_date) ||
          (params[:offer_request][:work_order_id].to_i != @offer_request.work_order_id.to_i) ||
          (params[:offer_request][:charge_account_id].to_i != @offer_request.charge_account_id.to_i) ||
          (params[:offer_request][:store_id].to_i != @offer_request.store_id.to_i) ||
          (params[:offer_request][:payment_method_id].to_i != @offer_request.payment_method_id.to_i) ||
          (params[:offer_request][:discount_pct].to_f != @offer_request.discount_pct.to_f) ||
          (params[:offer_request][:remarks].to_s != @offer_request.remarks))
        master_changed = true
      end

      respond_to do |format|
        if master_changed || items_changed
          @offer_request.updated_by = current_user.id if !current_user.nil?
          if @offer_request.update_attributes(params[:offer_request])
            format.html { redirect_to @offer_request,
                          notice: (crud_notice('updated', @offer_request) + "#{undo_link(@offer_request)}").html_safe }
            format.json { head :no_content }
          else
            @projects = projects_dropdown_edit(@offer_request.project)
            @work_orders = @offer_request.project.blank? ? work_orders_dropdown : @offer_request.project.work_orders.order(:order_no)
            @charge_accounts = work_order_charge_account(@offer_request)
            @stores = work_order_store(@offer_request)
            @suppliers = @offer_request.organization.blank? ? suppliers_dropdown : @offer_request.organization.suppliers(:supplier_code)
            @payment_methods = @offer_request.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@offer_request.organization_id)
            # @products = @offer_request.organization.blank? ? products_dropdown : @offer_request.organization.products(:product_code)
            format.html { render action: "edit" }
            format.json { render json: @offer_request.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to @offer_request }
          format.json { head :no_content }
        end
      end
    end

    # DELETE /offer_requests/1
    # DELETE /offer_requests/1.json
    def destroy
      @offer_request = OfferRequest.find(params[:id])

      respond_to do |format|
        if @offer_request.destroy
          format.html { redirect_to offer_requests_url,
                      notice: (crud_notice('destroyed', @offer_request) + "#{undo_link(@offer_request)}").html_safe }
          format.json { head :no_content }
        else
          format.html { redirect_to offer_requests_url, alert: "#{@offer_request.errors[:base].to_s}".gsub('["', '').gsub('"]', '') }
          format.json { render json: @offer_request.errors, status: :unprocessable_entity }
        end
      end
    end

    def offer_request_view_report
      manage_filter_state
      no = params[:No]
      supplier = params[:Supplier]
      project = params[:Project]
      order = params[:Order]
      account = params[:Account]
      # OCO
      init_oco if !session[:organization]
      # Initialize select_tags
      @supplier = !supplier.blank? ? Supplier.find(supplier).full_name : " "
      @project = !project.blank? ? Project.find(project).full_name : " "
      @work_order = !order.blank? ? WorkOrder.find(order).full_name : " "
      @charge_account = !account.blank? ? ChargeAccount.find(account).full_name : " "

      # Arrays for search
      if !supplier.blank?   # Offer requests that include current supplier
        @request_suppliers = OfferRequestSupplier.group(:offer_request_id).where(supplier_id: supplier)
      else
        @request_suppliers = OfferRequestSupplier.group(:offer_request_id)
      end
      @projects = projects_dropdown if @projects.nil?
      current_suppliers = @request_suppliers.blank? ? [0] : current_suppliers_for_index(@request_suppliers)
      current_projects = @projects.blank? ? [0] : current_projects_for_index(@projects)
      # If inverse no search is required
      no = !no.blank? && no[0] == '%' ? inverse_no_search(no) : no

      # Auto generate request
      @suppliers = suppliers_dropdown if @suppliers.nil?
      @current_projects = Project.where(id: current_projects) if @current_projects.nil?
      @search_projects = @current_projects.map{ |p| p.id }.map(&:inspect).join(',')
      @families = families_dropdown if @families.nil?
      # @charge_accounts = projects_charge_accounts(@current_projects) if @charge_accounts.nil?
      @stores = projects_stores(@current_projects) if @stores.nil?
      @payment_methods = payment_methods_dropdown if @payment_methods.nil?

      @search = OfferRequest.search do
        with :project_id, current_projects
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !no.blank?
          if no.class == Array
            with :request_no, no
          else
            with(:request_no).starting_with(no)
          end
        end
        if !supplier.blank?
          with :id, current_suppliers
        end
        if !project.blank?
          with :project_id, project
        end
        if !order.blank?
          with :work_order_id, order
        end
        data_accessor_for(OfferRequest).include = [{approved_offer: :supplier}]
        order_by :request_date, :asc
        paginate :per_page => OfferRequest.count
      end
      @offer_requests = @search.results

      title = t("activerecord.models.offer_request.few")
      @from = formatted_date(@offer_requests.first.request_date)
      @to = formatted_date(@offer_requests.last.request_date)
      respond_to do |format|
      # Render PDF
        if !@offer_requests.blank?
          format.pdf { send_data render_to_string,
                      filename: "#{title}_#{@from}-#{@to}.pdf",
                      type: 'application/pdf',
                      disposition: 'inline' }
          format.csv { send_data OfferRequest.to_csv(@offer_requests),
                       filename: "#{title}_#{@from}-#{@to}.csv",
                       type: 'application/csv',
                       disposition: 'inline' }
        else
          format.csv { redirect_to offer_requests_url, alert: I18n.t("ag2_purchase.ag2_purchase_track.index.error_report") }
          format.pdf { redirect_to offer_requests_url, alert: I18n.t("ag2_purchase.ag2_purchase_track.index.error_report") }
        end
      end
    end

    # Report
    def offer_request_form
      # Search offer request & items
      @offer_request = OfferRequest.find(params[:id])
      @items = @offer_request.offer_request_items.order('id')
      @suppliers = @offer_request.offer_request_suppliers.order('id')

      title = t("activerecord.models.offer_request.one")

      respond_to do |format|
        # Render PDF
        format.pdf { send_data render_to_string,
                     filename: "#{title}_#{@offer_request.full_no}.pdf",
                     type: 'application/pdf',
                     disposition: 'inline' }
      end
    end

    # Report no prices
    def offer_request_form_no_prices
      # Search offer request & items
      @offer_request = OfferRequest.find(params[:id])
      @items = @offer_request.offer_request_items.order('id')
      @suppliers = @offer_request.offer_request_suppliers.order('id')

      title = t("activerecord.models.offer_request.one")

      respond_to do |format|
        # Render PDF
        format.pdf { send_data render_to_string,
                     filename: "#{title}_#{@offer_request.full_no}.pdf",
                     type: 'application/pdf',
                     disposition: 'inline' }
      end
    end

    private

    def current_projects_for_index(_projects)
      # _current_projects = Project.where(id: _projects).pluck(:id)   # One more round to DB, but shorter
      _current_projects = []
      _projects.each do |i|
        _current_projects = _current_projects << i.id
      end
      _current_projects
    end

    # Returns offer requests that include these suppliers, for seach
    def current_suppliers_for_index(_suppliers)
      _current_suppliers = []
      # Add suppliers found
      _suppliers.each do |i|
        _current_suppliers = _current_suppliers << i.offer_request_id
      end
      _current_suppliers
    end

    def inverse_no_search(no)
      _numbers = []
      # Add numbers found
      OfferRequest.where('request_no LIKE ?', "#{no}").each do |i|
        _numbers = _numbers << i.request_no
      end
      _numbers = _numbers.blank? ? no : _numbers
    end

    def project_stores(_project)
      _array = []
      _stores = nil

      # Adding stores belonging to current project only
      # Stores with exclusive office
      if !_project.company_id.blank? && !_project.office_id.blank?
        _stores = Store.where("(company_id = ? AND office_id = ?)", _project.company_id, _project.office_id)
      elsif !_project.company_id.blank? && _project.office_id.blank?
        _stores = Store.where("(company_id = ?)", _project.company_id)
      elsif _project.company_id.blank? && !_project.office_id.blank?
        _stores = Store.where("(office_id = ?)", _project.office_id)
      else
        _stores = nil
      end
      ret_array(_array, _stores, 'id')
      # Stores with multiple offices
      if !_project.office_id.blank?
        _stores = StoreOffice.where("office_id = ?", _project.office_id)
        ret_array(_array, _stores, 'store_id')
      end

      # Returning founded stores
      _stores = Store.where(id: _array).order(:name)
    end

    # Stores belonging to projects
    def projects_stores(_projects)
      _array = []
      _ret = nil

      # Adding global stores, not JIT, belonging to current company
      if session[:company] != '0'
        _ret = Store.where("company_id = ? AND office_id IS NULL AND supplier_id IS NULL", session[:company].to_i)
      else
        _ret = session[:organization] != '0' ? Store.where("organization_id = ? AND office_id IS NULL AND supplier_id IS NULL", session[:organization].to_i) : Store.all
      end
      ret_array(_array, _ret, 'id')

      # Adding stores belonging to current projects (projects have company and office)
      _projects.each do |i|
        if !i.company_id.blank? && !i.office_id.blank?
          _ret = Store.where("(company_id = ? AND office_id = ?)", i.company_id, i.office_id)
        elsif !i.company_id.blank? && i.office_id.blank?
          _ret = Store.where("(company_id = ?)", i.company_id)
        elsif i.company_id.blank? && !i.office_id.blank?
          _ret = Store.where("(office_id = ?)", i.office_id)
        end
        ret_array(_array, _ret, 'id')
      end

      # Adding JIT stores
      _ret = session[:organization] != '0' ? Store.where("organization_id = ? AND company_id IS NULL AND NOT supplier_id IS NULL", session[:organization].to_i) : Store.where("(company_id IS NULL AND NOT supplier_id IS NULL)")
      ret_array(_array, _ret, 'id')

      # Returning founded stores
      _ret = Store.where(id: _array).order(:name)
    end

    # Charge accounts belonging to projects
    def projects_charge_accounts(_projects)
      _array = []
      _ret = nil

      # Adding charge accounts belonging to current projects
      _ret = ChargeAccount.expenditures.where(project_id: _projects)
      ret_array(_array, _ret, 'id')
      # _projects.each do |i|
      #   _ret = ChargeAccount.expenditures.where(project_id: i.id)
      #   ret_array(_array, _ret, 'id')
      # end

      # Adding global charge accounts belonging to projects organizations
      _sort_projects_by_organization = _projects.sort { |a,b| a.organization_id <=> b.organization_id }
      _previous_organization = _sort_projects_by_organization.first.organization_id
      _sort_projects_by_organization.each do |i|
        if _previous_organization != i.organization_id
          # when organization changes, process previous
          _ret = ChargeAccount.expenditures.where('(project_id IS NULL AND charge_accounts.organization_id = ?)', _previous_organization)
          ret_array(_array, _ret, 'id')
          _previous_organization = i.organization_id
        end
      end
      # last organization, process previous
      _ret = ChargeAccount.expenditures.where('(project_id IS NULL AND charge_accounts.organization_id = ?)', _previous_organization)
      ret_array(_array, _ret, 'id')

      # Returning founded charge accounts
      _ret = ChargeAccount.where(id: _array).order(:account_code)
    end

    def work_order_charge_account(_order)
      if _order.work_order.blank? || _order.work_order.charge_account.blank?
        _charge_account = _order.project.blank? ? projects_charge_accounts(projects) : charge_accounts_dropdown_edit(_order.project)
      else
        _charge_account = ChargeAccount.where("id = ?", _order.work_order.charge_account)
      end
      _charge_account
    end

    def work_order_store(_order)
      if _order.work_order.blank? || _order.work_order.store.blank?
        _store = _order.project.blank? ? stores_dropdown : project_stores(_order.project)
      else
        _store = Store.where("id = ?", _order.work_order.store)
      end
      _store
    end

    def projects_dropdown
      _array = []
      _projects = nil
      _offices = nil
      _companies = nil

      if session[:office] != '0'
        _projects = Project.where(office_id: session[:office].to_i).order(:project_code)
      elsif session[:company] != '0'
        _offices = current_user.offices
        if _offices.count > 1 # If current user has access to specific active company offices (more than one: not exclusive, previous if)
          _projects = Project.where('company_id = ? AND office_id IN (?)', session[:company].to_i, _offices)
        else
          _projects = Project.where(company_id: session[:company].to_i).order(:project_code)
        end
      else
        _offices = current_user.offices
        _companies = current_user.companies
        if _companies.count > 1 and _offices.count > 1 # If current user has access to specific active organization companies or offices (more than one: not exclusive, previous if)
          _projects = Project.where('company_id IN (?) AND office_id IN (?)', _companies, _offices)
        else
          _projects = session[:organization] != '0' ? Project.where(organization_id: session[:organization].to_i).order(:project_code) : Project.order(:project_code)
        end
      end

      # Returning founded projects
      ret_array(_array, _projects, 'id')
      _projects = Project.where(id: _array).order(:project_code)
    end

    def projects_dropdown_old
      if session[:office] != '0'
        _projects = Project.where(office_id: session[:office].to_i).order(:project_code)
      elsif session[:company] != '0'
        _projects = Project.where(company_id: session[:company].to_i).order(:project_code)
      else
        _projects = session[:organization] != '0' ? Project.where(organization_id: session[:organization].to_i).order(:project_code) : Project.order(:project_code)
      end
    end

    def projects_dropdown_edit(_project)
      _projects = projects_dropdown
      if _projects.blank?
        _projects = Project.where(id: _project)
      end
      _projects
    end

    def suppliers_dropdown
      session[:organization] != '0' ? Supplier.where(organization_id: session[:organization].to_i).order(:supplier_code) : Supplier.order(:supplier_code)
    end

    def families_dropdown
      session[:organization] != '0' ? ProductFamily.where(organization_id: session[:organization].to_i).by_code : ProductFamily.by_code
    end

    def charge_accounts_dropdown
      session[:organization] != '0' ? ChargeAccount.expenditures.where(organization_id: session[:organization].to_i) : ChargeAccount.expenditures
    end

    def charge_accounts_dropdown_edit(_project)
      #_accounts = ChargeAccount.where('project_id = ? OR project_id IS NULL', _project).order(:account_code)
      ChargeAccount.expenditures.where('project_id = ? OR (project_id IS NULL AND charge_accounts.organization_id = ?)', _project, _project.organization_id)
    end

    def stores_dropdown
      session[:organization] != '0' ? Store.where(organization_id: session[:organization].to_i).order(:name) : Store.order(:name)
    end

    def work_orders_dropdown
      session[:organization] != '0' ? WorkOrder.where(organization_id: session[:organization].to_i).order(:order_no) : WorkOrder.order(:order_no)
    end

    def payment_methods_dropdown
      session[:organization] != '0' ? payment_payment_methods(session[:organization].to_i) : payment_payment_methods(0)
    end

    def payment_payment_methods(_organization)
      if _organization != 0
        _methods = PaymentMethod.where("(flow = 3 OR flow = 2) AND organization_id = ?", _organization).order(:description)
      else
        _methods = PaymentMethod.where("flow = 3 OR flow = 2").order(:description)
      end
      _methods
    end

    def products_dropdown
      session[:organization] != '0' ? Product.where(organization_id: session[:organization].to_i).order(:product_code) : Product.order(:product_code)
    end

    def products_array(_products)
      _array = []
      _products.each do |i|
        _array = _array << [i.id, i.full_code, i.main_description[0,40]]
      end
      _array
    end

    def orders_array(_orders)
      _array = []
      _orders.each do |i|
        _array = _array << [i.id, i.full_name]
      end
      _array
    end

    # Returns offer array sorted by total from _offer_request
    def sort_offers_by_total(_offer_request)
      _offer_request.offers.sort_by(&:total)
    end

    # Returns _array from _ret table/model filled with _id attribute
    def ret_array(_array, _ret, _id)
      if !_ret.nil?
        _ret.each do |_r|
          _array = _array << _r.read_attribute(_id) unless _array.include? _r.read_attribute(_id)
        end
      end
    end

    def send_email(_offer_request)
      code = '$ok'
      from = nil

      # Search offer request & items
      @offer_request = OfferRequest.find(_offer_request)
      @items = @offer_request.offer_request_items.order(:id)
      @suppliers = @offer_request.offer_request_suppliers.order(:id)

      title = t("activerecord.models.offer_request.one") + "_" + @offer_request.full_no + ".pdf"
      from = !current_user.nil? ? User.find(current_user.id).email : User.find(@offer_request.created_by).email

      # Arrays of supplier email addresses & pdf's
      to = []
      pdf = []
      @suppliers.each do |i|
        _to = !i.supplier.email.blank? ? i.supplier.email : nil
        if !_to.blank?
          @supplier = i
          _pdf = render_to_string(filename: "#{title}", type: 'application/pdf')
          to = to << _to
          pdf = pdf << _pdf
        end
      end

      if from.blank? || to.count <= 0
        code = "$err"
      else
        # Send e-mail(s)
        for i in 0..to.count-1
          Notifier.send_offer_request(@offer_request, from, to[i], title, pdf[i]).deliver
        end
      end

      code
    end

    def send_approve_email(_offer)
      code = '$ok'
      from = nil
      to = nil

      from = !current_user.nil? ? User.find(current_user.id).email : User.find(_offer.approver_id).email
      to = !_offer.created_by.blank? ? User.find(_offer.created_by).email : nil

      if from.blank? || to.blank?
        code = "$err"
      else
        # Send e-mail
        Notifier.send_offer_approval(_offer, from, to).deliver
      end

      code
    end

    # Keeps filter state
    def manage_filter_state
      # search
      if params[:search]
        session[:search] = params[:search]
      elsif session[:search]
        params[:search] = session[:search]
      end
      # no
      if params[:No]
        session[:No] = params[:No]
      elsif session[:No]
        params[:No] = session[:No]
      end
      # supplier
      if params[:Supplier]
        session[:Supplier] = params[:Supplier]
      elsif session[:Supplier]
        params[:Supplier] = session[:Supplier]
      end
      # project
      if params[:Project]
        session[:Project] = params[:Project]
      elsif session[:Project]
        params[:Project] = session[:Project]
      end
      # order
      if params[:Order]
        session[:Order] = params[:Order]
      elsif session[:Order]
        params[:Order] = session[:Order]
      end
      # account
      if params[:Account]
        session[:Account] = params[:Account]
      elsif session[:Account]
        params[:Account] = session[:Account]
      end
    end

    def or_remove_filters
      params[:search] = ""
      params[:No] = ""
      params[:Supplier] = ""
      params[:Project] = ""
      params[:Order] = ""
      params[:Account] = ""
      return " "
    end

    def or_restore_filters
      params[:search] = session[:search]
      params[:No] = session[:No]
      params[:Supplier] = session[:Supplier]
      params[:Project] = session[:Project]
      params[:Order] = session[:Order]
      params[:Account] = session[:Account]
    end
  end
end
