require_dependency "ag2_purchase/application_controller"

module Ag2Purchase
  class SupplierInvoicesController < ApplicationController
    include ActionView::Helpers::NumberHelper
    before_filter :authenticate_user!
    load_and_authorize_resource
    skip_load_and_authorize_resource :only => [:si_remove_filters,
                                               :si_restore_filters,
                                               :si_attachment_changed,
                                               :si_update_attachment,
                                               :si_update_receipt_select_from_supplier,
                                               :si_update_order_select_from_supplier,
                                               :si_update_receipt_and_order_select_from_supplier,
                                               :si_update_receipt_and_order_select_from_project,
                                               :si_update_receipt_and_order_select_from_project_supplier,
                                               :si_update_selects_from_note,
                                               :si_update_selects_from_order,
                                               :si_update_selects_from_note_and_order,
                                               :si_update_product_select_from_note_item,
                                               :si_update_product_select_from_order_item,
                                               :si_update_product_select_from_note_and_order,
                                               :si_item_balance_check,
                                               :si_purchase_order_item_balance_check,
                                               :si_item_totals,
                                               :si_approval_totals,
                                               :si_update_description_prices_from_product_store,
                                               :si_update_description_prices_from_product,
                                               :si_update_amount_from_price_or_quantity,
                                               :si_update_approved_amount,
                                               :si_current_invoice_debt,
                                               :si_update_charge_account_from_order,
                                               :si_update_charge_account_from_project,
                                               :si_format_number,
                                               :si_format_number_4,
                                               :si_current_stock,
                                               :si_update_project_textfields_from_organization,
                                               :si_update_product_select_from_organization,
                                               :si_update_selects_from_company,
                                               :si_current_balance,
                                               :si_current_balance_order,
                                               :si_current_unbilled_balance_order,
                                               :si_generate_invoice,
                                               :si_generate_invoice_from_order,
                                               :si_update_payday_limit_from_method,
                                               :si_generate_no,
                                               :export_invoices]
    # Helper methods for
    # => index filters
    helper_method :si_remove_filters, :si_restore_filters

    # Public attachment for drag&drop
    $attachment = nil
    $attachment_changed = false

    # Attachment has changed
    def si_attachment_changed
      $attachment_changed = true
    end

    # Update attached file from drag&drop
    def si_update_attachment
      if !$attachment.nil?
        $attachment.destroy
        $attachment = Attachment.new
      end
      $attachment_changed = true
      $attachment.avatar = params[:file]
      $attachment.id = 1
      $attachment.save!
      if $attachment.save
        render json: { "image" => $attachment.avatar }
      else
        render json: { "image" => "" }
      end
    end

    # Update receipt note select at view from project
    def si_update_receipt_and_order_select_from_project
      project = params[:order]
      if project != '0'
        @project = Project.find(project)
        @receipt_notes = @project.blank? ? receipts_dropdown : receipts_dropdown_by_project(@project)
        @purchase_orders = @project.blank? ? unbilled_purchase_orders_dropdown : unbilled_purchase_orders_dropdown_by_project(@project)
      else
        @receipt_notes = receipts_dropdown
        @purchase_orders = unbilled_purchase_orders_dropdown
      end
      # Notes array
      @notes_dropdown = notes_array(@receipt_notes)
      # Orders array
      @purchase_orders_dropdown = purchase_orders_array(@purchase_orders)
      # Setup JSON
      @json_data = { "note" => @notes_dropdown, "order" => @purchase_orders_dropdown }
      render json: @json_data
    end

    # Update receipt note select at view from supplier
    def si_update_receipt_and_order_select_from_supplier
      supplier = params[:supplier]
      if supplier != '0'
        @supplier = Supplier.find(supplier)
        @receipt_notes = @supplier.blank? ? receipts_dropdown : receipts_dropdown_by_supplier(@supplier)
        @purchase_orders = @supplier.blank? ? unbilled_purchase_orders_dropdown : unbilled_purchase_orders_dropdown_by_supplier(@supplier)
      else
        @receipt_notes = receipts_dropdown
        @purchase_orders = unbilled_purchase_orders_dropdown
      end
      # Notes array
      @notes_dropdown = notes_array(@receipt_notes)
      # Orders array
      @purchase_orders_dropdown = purchase_orders_array(@purchase_orders)
      # Setup JSON
      @json_data = { "note" => @notes_dropdown, "order" => @purchase_orders_dropdown }
      render json: @json_data
    end

    # Update receipt note select at view from project & supplier
    def si_update_receipt_and_order_select_from_project_supplier
      project = params[:order]
      supplier = params[:supplier]
      if supplier != '0' && project != '0'
        @project = Project.find(project)
        @supplier = Supplier.find(supplier)
        if @project.blank? && @supplier.blank?
          # neither project nor supplier
          @receipt_notes = receipts_dropdown
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
        elsif !@project.blank? && @supplier.blank?
          # project only
          @receipt_notes = receipts_dropdown_by_project(@project)
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown_by_project(@project)
        elsif @project.blank? && !@supplier.blank?
          # supplier only
          @receipt_notes = receipts_dropdown_by_supplier(@supplier)
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown_by_supplier(@supplier)
        else
          # project and supplier
          @receipt_notes = receipts_dropdown_by_project_supplier(@project, @supplier)
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown_by_project_supplier(@project, @supplier)
        end
      elsif project != '0'
        @project = Project.find(project)
        if @project.blank?
          @receipt_notes = receipts_dropdown
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
        else
          @receipt_notes = receipts_dropdown_by_project(@project)
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown_by_project(@project)
        end
      elsif supplier != '0'
        @supplier = Supplier.find(supplier)
        if @supplier.blank?
          @receipt_notes = receipts_dropdown
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
        else
          @receipt_notes = receipts_dropdown_by_supplier(@supplier)
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown_by_supplier(@supplier)
        end
      else
        @receipt_notes = receipts_dropdown
        @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
      end
      # Notes array
      @notes_dropdown = notes_array(@receipt_notes)
      # Orders array
      @purchase_orders_dropdown = purchase_orders_array(@purchase_orders)
      # Setup JSON
      @json_data = { "note" => @notes_dropdown, "order" => @purchase_orders_dropdown }
      render json: @json_data
    end

    # Update receipt note select at view from supplier select
    def si_update_receipt_select_from_supplier
      supplier = params[:supplier]
      if supplier != '0'
        @supplier = Supplier.find(supplier)
        @receipt_notes = @supplier.blank? ? receipts_dropdown : receipts_dropdown_by_supplier(@supplier)
        # @receipt_notes = @supplier.blank? ? receipts_dropdown : @supplier.receipt_notes.unbilled(@supplier.organization_id, true)
      else
        @receipt_notes = receipts_dropdown
      end
      # Notes array
      @notes_dropdown = notes_array(@receipt_notes)
      # Setup JSON
      @json_data = { "note" => @notes_dropdown }
      render json: @json_data
    end

    # Update purchase order select at view from supplier select
    def si_update_order_select_from_supplier
      supplier = params[:supplier]
      if supplier != '0'
        @supplier = Supplier.find(supplier)
        @purchase_orders = @supplier.blank? ? unbilled_and_undelivered_purchase_orders_dropdown : unbilled_and_undelivered_purchase_orders_dropdown_by_supplier(@supplier)
      else
        @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
      end
      # Orders array
      @purchase_orders_dropdown = purchase_orders_array(@purchase_orders)
      # Setup JSON
      @json_data = { "order" => @purchase_orders_dropdown }
      render json: @json_data
    end

    # Update selects at view from receipt note & purchase order
    def si_update_selects_from_note_and_order
      o = params[:o]  # receipt note
      p = params[:p]  # purchase order
      project_id = 0
      work_order_id = 0
      charge_account_id = 0
      store_id = 0
      payment_method_id = 0
      if o != '0' && p != '0'
        # Receipt note
        @receipt_note = ReceiptNote.find(o)
        if @receipt_note.blank?
          @note_items = []
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @payment_methods = payment_methods_dropdown
        else
          @note_items = note_items_dropdown(@receipt_note)
          @projects = @receipt_note.project.blank? ? [] : Project.where(id: @receipt_note.project.id)
          @work_orders = @receipt_note.work_order.blank? ? [] : WorkOrder.where(id: @receipt_note.work_order.id)
          @charge_accounts = @receipt_note.charge_account.blank? ? [] : ChargeAccount.where(id: @receipt_note.charge_account.id)
          @stores = @receipt_note.store
          @payment_methods = @receipt_note.payment_method
        end
        if @note_items.blank?
          @products = @receipt_note.blank? ? products_dropdown : @receipt_note.organization.products.order(:product_code)
        else
          @products = @receipt_note.products.group(:product_code)
        end
        project_id = @projects.first.id rescue 0
        work_order_id = @work_orders.first.id rescue 0
        charge_account_id = @charge_accounts.first.id rescue 0
        store_id = @stores.id rescue 0
        payment_method_id = @payment_methods.id rescue 0
        # Purchase order
        @purchase_order = PurchaseOrder.find(p)
        if @purchase_order.blank?
          @order_items = []
        else
          @order_items = unbilled_order_items_dropdown(@purchase_order)
        end
      elsif o != '0'
        @receipt_note = ReceiptNote.find(o)
        if @receipt_note.blank?
          @note_items = []
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @payment_methods = payment_methods_dropdown
        else
          @note_items = note_items_dropdown(@receipt_note)
          @projects = @receipt_note.project.blank? ? [] : Project.where(id: @receipt_note.project.id)
          @work_orders = @receipt_note.work_order.blank? ? [] : WorkOrder.where(id: @receipt_note.work_order.id)
          @charge_accounts = @receipt_note.charge_account.blank? ? [] : ChargeAccount.where(id: @receipt_note.charge_account.id)
          @stores = @receipt_note.store
          @payment_methods = @receipt_note.payment_method
        end
        if @note_items.blank?
          @products = @receipt_note.blank? ? products_dropdown : @receipt_note.organization.products.order(:product_code)
        else
          @products = @receipt_note.products.group(:product_code)
        end
        project_id = @projects.first.id rescue 0
        work_order_id = @work_orders.first.id rescue 0
        charge_account_id = @charge_accounts.first.id rescue 0
        store_id = @stores.id rescue 0
        payment_method_id = @payment_methods.id rescue 0
      elsif p != '0'
        @purchase_order = PurchaseOrder.find(p)
        if @purchase_order.blank?
          @order_items = []
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @payment_methods = payment_methods_dropdown
        else
          @order_items = unbilled_order_items_dropdown(@purchase_order)
          @projects = @purchase_order.project.blank? ? [] : Project.where(id: @purchase_order.project.id)
          @work_orders = @purchase_order.work_order.blank? ? [] : WorkOrder.where(id: @purchase_order.work_order.id)
          @charge_accounts = @purchase_order.charge_account.blank? ? [] : ChargeAccount.where(id: @purchase_order.charge_account.id)
          @stores = @purchase_order.store
          @payment_methods = @purchase_order.payment_method
        end
        if @order_items.blank?
          @products = @purchase_order.blank? ? products_dropdown : @purchase_order.organization.products.order(:product_code)
        else
          @products = @purchase_order.products.group(:product_code)
        end
        project_id = @projects.first.id rescue 0
        work_order_id = @work_orders.first.id rescue 0
        charge_account_id = @charge_accounts.first.id rescue 0
        store_id = @stores.id rescue 0
        payment_method_id = @payment_methods.id rescue 0
      else
        @note_items = []
        @order_items = []
        @projects = projects_dropdown
        @work_orders = work_orders_dropdown
        @charge_accounts = projects_charge_accounts(@projects)
        @stores = stores_dropdown
        @payment_methods = payment_methods_dropdown
        @products = products_dropdown
      end
      # Work orders array
      @orders_dropdown = @work_orders.blank? ? [] : work_orders_array(@work_orders)
      # Receipt note items array
      @note_items_dropdown = @note_items.blank? ? [] : note_items_array(@note_items)
      # Purchase order items array
      @order_items_dropdown = @order_items.blank? ? [] : order_items_array(@order_items)
      # Products array
      @products_dropdown = @products.blank? ? [] : products_array(@products)
      # Setup JSON
      @json_data = { "project" => @projects, "work_order" => @orders_dropdown,
                     "charge_account" => @charge_accounts, "store" => @stores,
                     "payment_method" => @payment_methods, "product" => @products_dropdown,
                     "project_id" => project_id, "work_order_id" => work_order_id,
                     "charge_account_id" => charge_account_id, "store_id" => store_id,
                     "payment_method_id" => payment_method_id,
                     "note_item" => @note_items_dropdown, "order_item" => @order_items_dropdown }
      render json: @json_data
    end

    # Update selects at view from receipt note
    def si_update_selects_from_note
      o = params[:o]
      project_id = 0
      work_order_id = 0
      charge_account_id = 0
      store_id = 0
      payment_method_id = 0
      if o != '0'
        @receipt_note = ReceiptNote.find(o)
        if @receipt_note.blank?
          @note_items = []
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @payment_methods = payment_methods_dropdown
        else
          @note_items = note_items_dropdown(@receipt_note)
          @projects = @receipt_note.project.blank? ? [] : Project.where(id: @receipt_note.project.id)
          @work_orders = @receipt_note.work_order.blank? ? [] : WorkOrder.where(id: @receipt_note.work_order.id)
          @charge_accounts = @receipt_note.charge_account.blank? ? [] : ChargeAccount.where(id: @receipt_note.charge_account.id)
          @stores = @receipt_note.store
          @payment_methods = @receipt_note.payment_method
        end
        if @note_items.blank?
          @products = @receipt_note.blank? ? products_dropdown : @receipt_note.organization.products.order(:product_code)
        else
          @products = @receipt_note.products.group(:product_code)
        end
        project_id = @projects.first.id rescue 0
        work_order_id = @work_orders.first.id rescue 0
        charge_account_id = @charge_accounts.first.id rescue 0
        store_id = @stores.id rescue 0
        payment_method_id = @payment_methods.id rescue 0
      else
        @note_items = []
        @projects = projects_dropdown
        @work_orders = work_orders_dropdown
        @charge_accounts = projects_charge_accounts(@projects)
        @stores = stores_dropdown
        @payment_methods = payment_methods_dropdown
        @products = products_dropdown
      end
      # Work orders array
      @orders_dropdown = @work_orders.blank? ? [] : work_orders_array(@work_orders)
      # Note items array
      @note_items_dropdown = note_items_array(@note_items)
      # Products array
      @products_dropdown = products_array(@products)
      # Setup JSON
      @json_data = { "project" => @projects, "work_order" => @orders_dropdown,
                     "charge_account" => @charge_accounts, "store" => @stores,
                     "payment_method" => @payment_methods, "product" => @products_dropdown,
                     "project_id" => project_id, "work_order_id" => work_order_id,
                     "charge_account_id" => charge_account_id, "store_id" => store_id,
                     "payment_method_id" => payment_method_id, "note_item" => @note_items_dropdown }
      render json: @json_data
    end

    # Update selects at view from purchase order
    def si_update_selects_from_order
      o = params[:o]
      project_id = 0
      work_order_id = 0
      charge_account_id = 0
      store_id = 0
      payment_method_id = 0
      if o != '0'
        @purchase_order = PurchaseOrder.find(o)
        if @purchase_order.blank?
          @order_items = []
          @projects = projects_dropdown
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          @stores = stores_dropdown
          @payment_methods = payment_methods_dropdown
        else
          @order_items = unbilled_order_items_dropdown(@purchase_order)
          @projects = @purchase_order.project.blank? ? [] : Project.where(id: @purchase_order.project.id)
          @work_orders = @purchase_order.work_order.blank? ? [] : WorkOrder.where(id: @purchase_order.work_order.id)
          @charge_accounts = @purchase_order.charge_account.blank? ? [] : ChargeAccount.where(id: @purchase_order.charge_account.id)
          @stores = @purchase_order.store
          @payment_methods = @purchase_order.payment_method
        end
        if @order_items.blank?
          @products = @purchase_order.blank? ? products_dropdown : @purchase_order.organization.products.order(:product_code)
        else
          @products = @purchase_order.products.group(:product_code)
        end
        project_id = @projects.first.id rescue 0
        work_order_id = @work_orders.first.id rescue 0
        charge_account_id = @charge_accounts.first.id rescue 0
        store_id = @stores.id rescue 0
        payment_method_id = @payment_methods.id rescue 0
      else
        @order_items = []
        @projects = projects_dropdown
        @work_orders = work_orders_dropdown
        @charge_accounts = projects_charge_accounts(@projects)
        @stores = stores_dropdown
        @payment_methods = payment_methods_dropdown
        @products = products_dropdown
      end
      # Work orders array
      @orders_dropdown = @work_orders.blank? ? [] : work_orders_array(@work_orders)
      # Purchase order items array
      @order_items_dropdown = order_items_array(@order_items)
      # Products array
      @products_dropdown = products_array(@products)
      # Setup JSON
      @json_data = { "project" => @projects, "work_order" => @orders_dropdown,
                     "charge_account" => @charge_accounts, "store" => @stores,
                     "payment_method" => @payment_methods, "product" => @products_dropdown,
                     "project_id" => project_id, "work_order_id" => work_order_id,
                     "charge_account_id" => charge_account_id, "store_id" => store_id,
                     "payment_method_id" => payment_method_id, "note_item" => @order_items_dropdown }
      render json: @json_data
    end

    # Update product and items at view from receipt note & purchase order
    def si_update_product_select_from_note_and_order
      o = params[:o]  # receipt note
      p = params[:p]  # purchase order
      if o != '0' && p != '0'
        # Receipt note
        @receipt_note = ReceiptNote.find(o)
        if @receipt_note.blank?
          @note_items = []
        else
          @note_items = note_items_dropdown(@receipt_note)
        end
        if @note_items.blank?
          @products = @receipt_note.blank? ? products_dropdown : @receipt_note.organization.products.order(:product_code)
        else
          @products = @receipt_note.products.group(:product_code)
        end
        # Purchase order
        @purchase_order = PurchaseOrder.find(p)
        if @purchase_order.blank?
          @order_items = []
        else
          @order_items = unbilled_order_items_dropdown(@purchase_order)
        end
      elsif o != '0'
        @receipt_note = ReceiptNote.find(o)
        if @receipt_note.blank?
          @note_items = []
        else
          @note_items = note_items_dropdown(@receipt_note)
        end
        if @note_items.blank?
          @products = @receipt_note.blank? ? products_dropdown : @receipt_note.organization.products.order(:product_code)
        else
          @products = @receipt_note.products.group(:product_code)
        end
        @order_items = []
      elsif p != '0'
        @purchase_order = PurchaseOrder.find(p)
        if @purchase_order.blank?
          @order_items = []
        else
          @order_items = unbilled_order_items_dropdown(@purchase_order)
        end
        if @order_items.blank?
          @products = @purchase_order.blank? ? products_dropdown : @purchase_order.organization.products.order(:product_code)
        else
          @products = @purchase_order.products.group(:product_code)
        end
        @note_items = []
      else
        @note_items = []
        @order_items = []
        @products = products_dropdown
      end
      # Receipt note items array
      @note_items_dropdown = @note_items.blank? ? [] : note_items_array(@note_items)
      # Purchase order items array
      @order_items_dropdown = @order_items.blank? ? [] : order_items_array(@order_items)
      # Products array
      @products_dropdown = @products.blank? ? [] : products_array(@products)
      # Setup JSON
      @json_data = { "product" => @products_dropdown, "note_item" => @note_items_dropdown, "order_item" => @order_items_dropdown }
      render json: @json_data
    end

    # Update product select at view from receipt note item
    def si_update_product_select_from_note_item
      i = params[:i]
      product_id = 0
      if i != '0'
        @item = ReceiptNoteItem.find(i)
        product_id = @item.blank? ? 0 : @item.product_id
      end
      # Setup JSON
      @json_data = { "product" => product_id }
      render json: @json_data
    end

    # Update product select at view from purchase order item
    def si_update_product_select_from_order_item
      i = params[:i]
      product_id = 0
      if i != '0'
        @item = PurchaseOrderItem.find(i)
        product_id = @item.blank? ? 0 : @item.product_id
      end
      # Setup JSON
      @json_data = { "product" => product_id }
      render json: @json_data
    end

    # Is quantity greater than item unbilled balance?
    def si_item_balance_check
      i = params[:i]
      qty = params[:qty].to_f / 10000
      bal = 0
      alert = ""
      if i != '0'
        bal = ReceiptNoteItem.find(i).balance rescue 0
        if qty > bal
          qty = number_with_precision(qty.round(4), precision: 4, delimiter: I18n.locale == :es ? "." : ",")
          bal = number_with_precision(bal.round(4), precision: 4, delimiter: I18n.locale == :es ? "." : ",")
          alert = I18n.t("activerecord.models.supplier_invoice_item.quantity_greater_than_balance", qty: qty, bal: bal)
        end
      end
      # Setup JSON
      @json_data = { "alert" => alert }
      render json: @json_data
    end

    # Is quantity greater than item unbilled (purchase order) balance?
    def si_purchase_order_item_balance_check
      i = params[:i]
      qty = params[:qty].to_f / 10000
      bal = 0
      alert = ""
      if i != '0'
        bal = PurchaseOrderItem.find(i).unbilled_balance rescue 0
        if qty > bal
          qty = number_with_precision(qty.round(4), precision: 4, delimiter: I18n.locale == :es ? "." : ",")
          bal = number_with_precision(bal.round(4), precision: 4, delimiter: I18n.locale == :es ? "." : ",")
          alert = I18n.t("activerecord.models.supplier_invoice_item.quantity_greater_than_balance", qty: qty, bal: bal)
        end
      end
      # Setup JSON
      @json_data = { "alert" => alert }
      render json: @json_data
    end

    # Calculate and format item totals properly
    def si_item_totals
      qty = params[:qty].to_f / 10000
      amount = params[:amount].to_f / 10000
      tax = params[:tax].to_f / 10000
      discount_p = params[:discount_p].to_f / 100
      withholding = params[:withholding].to_f / 10000
      # Bonus
      discount = discount_p != 0 ? amount * (discount_p / 100) : 0
      # Taxable
      taxable = amount - discount
      # Taxes
      tax = tax - (tax * (discount_p / 100)) if discount_p != 0
      # Total
      total = taxable + tax + withholding
      # Format output values
      qty = number_with_precision(qty.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      discount = number_with_precision(discount.round(4), precision: 4)
      taxable = number_with_precision(taxable.round(4), precision: 4)
      total = number_with_precision(total.round(4), precision: 4)
      # Setup JSON hash
      @json_data = { "qty" => qty.to_s, "amount" => amount.to_s, "tax" => tax.to_s,
                     "discount" => discount.to_s, "taxable" => taxable.to_s, "total" => total.to_s }
      render json: @json_data
    end

    # Calculate and format approval totals properly
    def si_approval_totals
      total = params[:amount].to_f / 10000
      # Format output values
      total = number_with_precision(total.round(4), precision: 4)
      # Setup JSON hash
      @json_data = { "total" => total.to_s }
      render json: @json_data
    end

    # Update description and prices text fields at view from product & store selects
    def si_update_description_prices_from_product_store
      product = params[:product]
      store = params[:store]
      supplier = params[:supplier]
      description = ""
      qty = 0
      price = 0
      discount_p = 0
      discount = 0
      code = ""
      amount = 0
      tax_type_id = 0
      tax_type_tax = 0
      tax = 0
      current_stock = 0
      if product != '0'
        @product = Product.find(product)
        # Assignment
        description = @product.main_description[0,40]
        qty = params[:qty].to_f / 10000
        # Use purchase price, if any. Otherwise, the reference price
        price, discount_p, code = product_price_to_apply(@product, supplier)
        if discount_p > 0
          discount = price * (discount_p / 100)
        end
        amount = qty * (price - discount)
        tax_type_id = @product.tax_type.id
        tax_type_tax = @product.tax_type.tax
        tax = amount * (tax_type_tax / 100)
        if store != 0
          current_stock = Stock.find_by_product_and_store(product, store).current rescue 0
        end
      end
      # Format numbers
      price = number_with_precision(price.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      current_stock = number_with_precision(current_stock.round(4), precision: 4)
      discount_p = number_with_precision(discount_p.round(2), precision: 2)
      discount = number_with_precision(discount.round(4), precision: 4)
      # Setup JSON hash
      @json_data = { "description" => description, "price" => price.to_s, "amount" => amount.to_s,
                     "tax" => tax.to_s, "type" => tax_type_id, "stock" => current_stock.to_s,
                     "discountp" => discount_p, "discount" => discount, "code" => code }
      render json: @json_data
    end

    # Update description and prices text fields at view from product select
    def si_update_description_prices_from_product
      product = params[:product]
      supplier = params[:supplier]
      tbl = params[:tbl]
      description = ""
      qty = 0
      price = 0
      discount_p = 0
      discount = 0
      code = ""
      amount = 0
      tax_type_id = 0
      tax_type_tax = 0
      tax = 0
      if product != '0'
        @product = Product.find(product)
        # Assignment
        description = @product.main_description[0,40]
        qty = params[:qty].to_f / 10000
        # Use purchase price, if any. Otherwise, the reference price
        price, discount_p, code = product_price_to_apply(@product, supplier)
        if discount_p > 0
          discount = price * (discount_p / 100)
        end
        amount = qty * (price - discount)
        tax_type_id = @product.tax_type.id
        tax_type_tax = @product.tax_type.tax
        tax = amount * (tax_type_tax / 100)
      end
      # Format numbers
      price = number_with_precision(price.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      discount_p = number_with_precision(discount_p.round(2), precision: 2)
      discount = number_with_precision(discount.round(4), precision: 4)
      # Setup JSON hash
      @json_data = { "description" => description, "price" => price.to_s, "amount" => amount.to_s,
                     "tax" => tax.to_s, "type" => tax_type_id,
                     "discountp" => discount_p, "discount" => discount, "code" => code, "tbl" => tbl.to_s }
      render json: @json_data
    end

    # Update amount and tax text fields at view (quantity or price changed)
    def si_update_amount_from_price_or_quantity
      price = params[:price].to_f / 10000
      qty = params[:qty].to_f / 10000
      tax_type = params[:tax_type].to_i
      discount_p = params[:discount_p].to_f / 100
      discount = params[:discount].to_f / 10000
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
      if discount_p > 0
        discount = price * (discount_p / 100)
      end
      amount = qty * (price - discount)
      tax = amount * (tax / 100)
      qty = number_with_precision(qty.round(4), precision: 4)
      price = number_with_precision(price.round(4), precision: 4)
      amount = number_with_precision(amount.round(4), precision: 4)
      tax = number_with_precision(tax.round(4), precision: 4)
      discount_p = number_with_precision(discount_p.round(2), precision: 2)
      discount = number_with_precision(discount.round(4), precision: 4)
      @json_data = { "quantity" => qty.to_s, "price" => price.to_s, "amount" => amount.to_s, "tax" => tax.to_s,
                     "discountp" => discount_p.to_s, "discount" => discount.to_s, "tbl" => tbl.to_s }
      render json: @json_data
    end

    # Update approved amount text field, checking current debt (approved amount changed)
    def si_update_approved_amount
      amount = params[:amount].to_f / 10000
      invoice_id = params[:invoice]
      tbl = params[:tbl]
      debt = SupplierInvoice.find(invoice_id).debt rescue -1
      not_yet_approved = SupplierInvoice.find(invoice_id).amount_not_yet_approved rescue -1
      amount = (amount > debt || amount > not_yet_approved) ? '$err' : number_with_precision(amount.round(4), precision: 4)
      @json_data = { "amount" => amount.to_s, "tbl" => tbl.to_s }
      render json: @json_data
    end

    # Current invoice debt
    def si_current_invoice_debt
      invoice_id = params[:invoice]
      debt = SupplierInvoice.find(invoice_id).debt rescue -1
      not_yet_approved = SupplierInvoice.find(invoice_id).amount_not_yet_approved rescue -1
      debt = debt < not_yet_approved ? number_with_precision(debt.round(4), precision: 4) : number_with_precision(not_yet_approved.round(4), precision: 4)
      @json_data = { "debt" => debt.to_s }
      render json: @json_data
    end

    # Update charge account and store text fields at view from work order select
    def si_update_charge_account_from_order
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
    def si_update_charge_account_from_project
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
      @orders_dropdown = work_orders_array(@work_order)
      # Setup JSON
      @json_data = { "work_order" => @orders_dropdown, "charge_account" => @charge_account, "store" => @store }
      render json: @json_data
    end

    # Format numbers properly
    def si_format_number
      num = params[:num].to_f / 100
      num = number_with_precision(num.round(2), precision: 2)
      @json_data = { "num" => num.to_s }
      render json: @json_data
    end
    def si_format_number_4
      num = params[:num].to_f / 10000
      num = number_with_precision(num.round(4), precision: 4)
      @json_data = { "num" => num.to_s }
      render json: @json_data
    end

    # Update current stock text field at view from store select
    def si_current_stock
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
    def si_update_project_textfields_from_organization
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
        @companies = @organization.blank? ? companies_dropdown : companies_dropdown_edit(@organization)
      else
        @suppliers = suppliers_dropdown
        @projects = projects_dropdown
        @work_orders = work_orders_dropdown
        @charge_accounts = projects_charge_accounts(@projects)
        @stores = stores_dropdown
        @payment_methods = payment_methods_dropdown
        @products = products_dropdown
        @companies = companies_dropdown
      end
      # Work orders array
      @orders_dropdown = work_orders_array(@work_orders)
      # Products array
      @products_dropdown = products_array(@products)
      # Setup JSON
      @json_data = { "supplier" => @suppliers, "project" => @projects, "work_order" => @orders_dropdown,
                     "charge_account" => @charge_accounts, "store" => @stores,
                     "payment_method" => @payment_methods, "product" => @products_dropdown,
                     "company" => @companies }
      render json: @json_data
    end

    # Update product select at view from organization select
    def si_update_product_select_from_organization
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

    # Update selects at view from company select
    def si_update_selects_from_company
      company = params[:org]
      if company != '0'
        @company = Company.find(company)
        @projects = @company.blank? ? projects_dropdown : @company.projects.order(:project_code)
      else
        @projects = projects_dropdown
      end
      # Setup JSON
      @json_data = { "project" => @projects }
      render json: @json_data
    end

    # Update receipt note balance (unbilled) text field at view from receipt select
    def si_current_balance
      order = params[:order]
      current_balance = 0
      if order != '0'
        current_balance = ReceiptNote.find(order).balance rescue 0
      end
      # Format numbers
      current_balance = number_with_precision(current_balance.round(4), precision: 4)
      # Setup JSON
      @json_data = { "balance" => current_balance.to_s }
      render json: @json_data
    end

    # Update purchase order balance (undelivered) text field at view from order select
    def si_current_balance_order
      order = params[:order]
      current_balance = 0
      if order != '0'
        current_balance = PurchaseOrder.find(order).balance rescue 0
      end
      # Format numbers
      current_balance = number_with_precision(current_balance.round(4), precision: 4)
      # Setup JSON
      @json_data = { "balance" => current_balance.to_s }
      render json: @json_data
    end

    # Update purchase order balance (unbilled) text field at view from order select
    def si_current_unbilled_balance_order
      order = params[:order]
      current_balance = 0
      if order != '0'
        current_balance = PurchaseOrder.find(order).unbilled_balance rescue 0
      end
      # Format numbers
      current_balance = number_with_precision(current_balance.round(4), precision: 4)
      # Setup JSON
      @json_data = { "balance" => current_balance.to_s }
      render json: @json_data
    end

    def si_update_payday_limit_from_method
      order = params[:order]
      payday_limit = Time.new
      if order != '0'
        payment_method = PaymentMethod.find(order)
        days_to_expiration = payment_method.expiration_days.blank? ? 0 : payment_method.expiration_days
        payday_limit = payday_limit + days_to_expiration.days
      end
      # Setup JSON
      @json_data = { "payday_limit" => payday_limit.strftime("%Y-%m-%d") }
      render json: @json_data
    end

    # Generate new invoice from receipt note
    def si_generate_invoice
      supplier = params[:supplier]
      notes = params[:request]
      invoice_no = params[:offer_no]
      invoice_date = params[:offer_date]  # YYYYMMDD
      internal_no = params[:internal_no]
      posted_at = params[:posted_at]  # YYYYMMDD
      company = params[:company]
      invoice = nil
      invoice_item = nil
      code = ''
      first = true

      # notes.split(",").map(&:to_i) # Convert to array, map each element to int
      notes = notes.split(",")

      # Format offer_date
      invoice_date = (invoice_date[0..3] + '-' + invoice_date[4..5] + '-' + invoice_date[6..7]).to_date
      posted_at = (posted_at[0..3] + '-' + posted_at[4..5] + '-' + posted_at[6..7]).to_date

      if notes.count == 1
        # Only one note
        if notes[0] != '0'
          receipt_note = ReceiptNote.find(notes[0]) rescue nil
          receipt_note_items = receipt_note.receipt_note_items rescue nil
          if !receipt_note.nil? && !receipt_note_items.nil?
            # Try to save new invoice
            invoice = new_invoice(receipt_note, invoice_no, invoice_date, internal_no, posted_at, company)
            # One note only: Must save receipt_note_id, work_order_id & charge_account_id
            invoice.receipt_note_id = receipt_note.id
            invoice.work_order_id = receipt_note.work_order_id
            invoice.charge_account_id = receipt_note.charge_account_id
            # One note only: Discount must be saved as well
            invoice.discount_pct = receipt_note.discount_pct
            invoice.discount = receipt_note.discount
            if invoice.save
              # Try to save new invoice items
              receipt_note_items.each do |i|
                if i.balance != 0 # Only items not billed yet
                  invoice_item = new_invoice_item(invoice, i)
                  if !invoice_item.save
                    # Can't save invoice item (exit)
                    code = '$write'
                    break
                  end   # !invoice_item.save?
                end   # i.balance != 0
              end   # receipt_note_items.each do |i|
              # Update totals
              invoice.update_column(:totals, SupplierInvoice.find(invoice.id).total)
            else
              # Can't save invoice
              code = '$write'
            end   # invoice.save?
          else
            # Receipt note or items not found
            code = '$err'
          end   # !receipt_note.nil? && !receipt_note_items.nil?
        else
          # Receipt note 0
          code = '$err'
        end   # note != '0'
      else
        # Loop thru notes and create invoice
        notes.each do |note|
          if note != '0'
            receipt_note = ReceiptNote.find(note) rescue nil
            receipt_note_items = receipt_note.receipt_note_items rescue nil
            if !receipt_note.nil? && !receipt_note_items.nil?
              # If it's first note, must initialize new invoice; if not, update already initialized one
              if first
                invoice = new_invoice(receipt_note, invoice_no, invoice_date, internal_no, posted_at, company)
                invoice.remarks = I18n.t("activerecord.attributes.supplier_invoice.receipt_notes") + ': ' + receipt_note.receipt_no
                first = false
              else
                invoice.discount = invoice.discount + receipt_note.discount
                invoice.remarks = invoice.remarks + ', ' + receipt_note.receipt_no
              end
              if invoice.save
                # Try to save new invoice items
                receipt_note_items.each do |i|
                  if i.balance != 0 # Only items not billed yet
                    invoice_item = new_invoice_item(invoice, i)
                    if !invoice_item.save
                      # Can't save invoice item (exit)
                      code = '$write'
                      break
                    end   # !invoice_item.save?
                  end   # i.balance != 0
                end   # receipt_note_items.each do |i|
                # Update totals
                invoice.update_column(:totals, SupplierInvoice.find(invoice.id).total)
              else
                # Can't save invoice
                code = '$write'
                break
              end   # invoice.save?
            else
              # Receipt note or items not found
              code = '$err'
            end   # !receipt_note.nil? && !receipt_note_items.nil?
          else
            # Receipt note 0
            code = '$err'
          end   # note != '0'
        end   # notes.each do |note|
      end   # notes.count == 1

      if code == ''
        code = I18n.t("ag2_purchase.supplier_invoices.generate_invoice_ok", var: invoice.id.to_s)
      end

      @json_data = { "code" => code }
      render json: @json_data
    end

    # Generate new invoice from purchase order
    def si_generate_invoice_from_order
      supplier = params[:supplier]
      orders = params[:order]
      invoice_no = params[:offer_no]
      invoice_date = params[:offer_date]  # YYYYMMDD
      internal_no = params[:internal_no]
      posted_at = params[:posted_at]  # YYYYMMDD
      company = params[:company]
      invoice = nil
      invoice_item = nil
      code = ''
      first = true

      orders = orders.split(",")

      # Format offer_date
      invoice_date = (invoice_date[0..3] + '-' + invoice_date[4..5] + '-' + invoice_date[6..7]).to_date
      posted_at = (posted_at[0..3] + '-' + posted_at[4..5] + '-' + posted_at[6..7]).to_date

      if orders.count == 1
        # Only one order
        if orders[0] != '0'
          purchase_order = PurchaseOrder.find(orders[0]) rescue nil
          purchase_order_items = purchase_order.purchase_order_items rescue nil
          if !purchase_order.nil? && !purchase_order_items.nil?
            # Try to save new invoice
            invoice = new_invoice(purchase_order, invoice_no, invoice_date, internal_no, posted_at, company)
            # One order only: Must save purchase_order_id, work_order_id & charge_account_id
            invoice.purchase_order_id = purchase_order.id
            invoice.work_order_id = purchase_order.work_order_id
            invoice.charge_account_id = purchase_order.charge_account_id
            # One order only: Discount must be saved as well
            invoice.discount_pct = purchase_order.discount_pct
            invoice.discount = purchase_order.discount
            if invoice.save
              # Try to save new invoice items
              purchase_order_items.each do |i|
                if i.balance != 0 # Only items not billed yet
                  invoice_item = new_invoice_item(invoice, i)
                  if !invoice_item.save
                    # Can't save invoice item (exit)
                    code = '$write'
                    break
                  end   # !invoice_item.save?
                end   # i.balance != 0
              end   # purchase_order_items.each do |i|
              # Update totals
              invoice.update_column(:totals, SupplierInvoice.find(invoice.id).total)
            else
              # Can't save invoice
              code = '$write'
            end   # invoice.save?
          else
            # Purchase order or items not found
            code = '$err'
          end   # !purchase_order.nil? && !purchase_order_items.nil?
        else
          # Purchase order 0
          code = '$err'
        end   # orders[0] != '0'
      else
        # Loop thru orders and create invoice
        orders.each do |note|
          if note != '0'
            purchase_order = PurchaseOrder.find(note) rescue nil
            purchase_order_items = purchase_order.purchase_order_items rescue nil
            if !purchase_order.nil? && !purchase_order_items.nil?
              # If it's first order, must initialize new invoice; if not, update already initialized one
              if first
                invoice = new_invoice(purchase_order, invoice_no, invoice_date, internal_no, posted_at, company)
                invoice.remarks = I18n.t("activerecord.attributes.supplier_invoice.purchase_orders") + ': ' + purchase_order.order_no
                first = false
              else
                invoice.discount = invoice.discount + purchase_order.discount
                invoice.remarks = invoice.remarks + ', ' + purchase_order.order_no
              end
              if invoice.save
                # Try to save new invoice items
                purchase_order_items.each do |i|
                  if i.balance != 0 # Only items not billed yet
                    invoice_item = new_invoice_item(invoice, i)
                    if !invoice_item.save
                      # Can't save invoice item (exit)
                      code = '$write'
                      break
                    end   # !invoice_item.save?
                  end   # i.balance != 0
                end   # purchase_order_items.each do |i|
                # Update totals
                invoice.update_column(:totals, SupplierInvoice.find(invoice.id).total)
              else
                # Can't save invoice
                code = '$write'
                break
              end   # invoice.save?
            else
              # Purchase order or items not found
              code = '$err'
            end   # !purchase_order.nil? && !purchase_order_items.nil?
          else
            # Purchase order 0
            code = '$err'
          end   # note != '0'
        end   # orders.each do |note|
      end   # orders.count == 1

      if code == ''
        code = I18n.t("ag2_purchase.supplier_invoices.generate_invoice_ok", var: invoice.id.to_s)
      end

      @json_data = { "code" => code }
      render json: @json_data
    end

    # Initialize new invoice
    def new_invoice(rnote_or_porder, invoice_no, invoice_date, internal_no, posted_at, company)
      invoice = SupplierInvoice.new
      invoice.invoice_no = invoice_no
      invoice.internal_no = internal_no
      invoice.supplier_id = rnote_or_porder.supplier_id
      invoice.payment_method_id = rnote_or_porder.payment_method_id
      invoice.invoice_date = invoice_date
      invoice.posted_at = posted_at
      invoice.project_id = rnote_or_porder.project_id
      invoice.organization_id = rnote_or_porder.organization_id
      invoice.company_id = company.to_i
      invoice.created_by = current_user.id if !current_user.nil?
      return invoice
    end

    # Initialize new invoice item
    def new_invoice_item(invoice, i)
      invoice_item = SupplierInvoiceItem.new
      if i.class.name == 'ReceiptNoteItem'
        invoice_item.receipt_note_id = i.receipt_note_id
        invoice_item.receipt_note_item_id = i.id
      else
        invoice_item.purchase_order_id = i.purchase_order_id
        invoice_item.purchase_order_item_id = i.id
      end
      invoice_item.supplier_invoice_id = invoice.id
      invoice_item.product_id = i.product_id
      invoice_item.code = i.code
      invoice_item.description = i.description
      invoice_item.quantity = i.balance
      invoice_item.price = i.price
      invoice_item.discount_pct = i.discount_pct
      invoice_item.discount = i.discount
      invoice_item.tax_type_id = i.tax_type_id
      invoice_item.work_order_id = i.work_order_id
      invoice_item.project_id = i.project_id
      if !i.charge_account_id.blank?
        invoice_item.charge_account_id = i.charge_account_id
      else
        invoice_item.charge_account_id = ChargeAccount.expenditures(i.project_id).first.id
      end
      invoice_item.created_by = current_user.id if !current_user.nil?
      return invoice_item
    end

    def export_invoices
      manage_filter_state
      no = params[:No]
      supplier = params[:Supplier]
      project = params[:Project]
      order = params[:Order]
      # OCO
      init_oco if !session[:organization]
      # Initialize select_tags
      @supplier = !supplier.blank? ? Supplier.find(supplier).full_name : " "
      @project = !project.blank? ? Project.find(project).full_name : " "
      @work_order = !order.blank? ? WorkOrder.find(order).full_name : " "
      @receipt_notes = receipts_dropdown if @receipt_notes.nil?
      @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown if @purchase_orders.nil?

      # Arrays for search
      @projects = projects_dropdown if @projects.nil?
      current_projects = @projects.blank? ? [0] : current_projects_for_index(@projects)
      # If inverse no search is required
      no = !no.blank? && no[0] == '%' ? inverse_no_search(no) : no

      @search = SupplierInvoice.search do
        with :project_id, current_projects
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !no.blank?
          if no.class == Array
            with :invoice_no, no
          else
            with(:invoice_no).starting_with(no)
          end
        end
        if !supplier.blank?
          with :supplier_id, supplier
        end
        if !project.blank?
          with :project_id, project
        end
        if !order.blank?
          with :work_order_id, order
        end
        data_accessor_for(SupplierInvoice).include = [:supplier_invoice_approvals, :supplier, :project]
        order_by :id, :asc
        paginate :per_page => SupplierInvoice.count
      end
      @supplier_invoices = @search.results

      title = t("activerecord.models.supplier_invoice.few")
      respond_to do |format|
        # Render PDF
        if !@supplier_invoices.blank?
          format.pdf { send_data render_to_string,
                       filename: "#{title}.pdf",
                       type: 'application/pdf',
                       disposition: 'inline' }
          format.csv { send_data SupplierInvoice.to_report_invoices_csv(@supplier_invoices),
                       filename: "#{title}.csv",
                       type: 'application/csv',
                       disposition: 'inline' }
        else
          format.csv { redirect_to supplier_invoices_url, alert: I18n.t("ag2_purchase.ag2_purchase_track.index.error_report") }
          format.pdf { redirect_to supplier_invoices_url, alert: I18n.t("ag2_purchase.ag2_purchase_track.index.error_report") }
        end
      end
    end

    # Update internal number at view (generate_code_btn)
    def si_generate_no
      company = params[:company]
      posted_at = params[:posted_at]

      # Builds no, if possible
      code = '$err'
      if company != '$' && posted_at != '$'
        code = si_next_no(company, Time.parse(posted_at))
      end
      @json_data = { "code" => code }
      render json: @json_data
    end

    #
    # Default Methods
    #
    # GET /supplier_invoices
    # GET /supplier_invoices.json
    def index
      manage_filter_state
      no = params[:No]
      supplier = params[:Supplier]
      project = params[:Project]
      order = params[:Order]
      # OCO
      init_oco if !session[:organization]
      # Initialize select_tags
      @supplier = !supplier.blank? ? Supplier.find(supplier).full_name : " "
      @project = !project.blank? ? Project.find(project).full_name : " "
      @work_order = !order.blank? ? WorkOrder.find(order).full_name : " "
      @receipt_notes = receipts_dropdown if @receipt_notes.nil?
      @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown if @purchase_orders.nil?

      # Arrays for search
      @projects = projects_dropdown if @projects.nil?
      current_projects = @projects.blank? ? [0] : current_projects_for_index(@projects)
      # If inverse no search is required
      no = !no.blank? && no[0] == '%' ? inverse_no_search(no) : no

      @search = SupplierInvoice.search do
        with :project_id, current_projects
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !no.blank?
          if no.class == Array
            with :invoice_no, no
          else
            with(:invoice_no).starting_with(no)
          end
        end
        if !supplier.blank?
          with :supplier_id, supplier
        end
        if !project.blank?
          with :project_id, project
        end
        if !order.blank?
          with :work_order_id, order
        end
        data_accessor_for(SupplierInvoice).include = [:supplier_invoice_approvals, :supplier, :project]
        order_by :id, :desc
        paginate :page => params[:page] || 1, :per_page => per_page
      end
      @supplier_invoices = @search.results

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @supplier_invoices }
        format.js
      end
    end

    # GET /supplier_invoices/1
    # GET /supplier_invoices/1.json
    def show
      @breadcrumb = 'read'
      @supplier_invoice = SupplierInvoice.find(params[:id])
      @items = @supplier_invoice.supplier_invoice_items.paginate(:page => params[:page], :per_page => per_page).order('id')
      @approvals = @supplier_invoice.supplier_invoice_approvals.paginate(:page => params[:page], :per_page => per_page).order('id')

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @supplier_invoice }
      end
    end

    # GET /supplier_invoices/new
    # GET /supplier_invoices/new.json
    def new
      @breadcrumb = 'create'
      @supplier_invoice = SupplierInvoice.new
      $attachment_changed = false
      $attachment = Attachment.new
      destroy_attachment
      @projects = projects_dropdown
      # @search_projects = @projects.map{ |p| p.id }.map(&:inspect).join(',')
      @work_orders = work_orders_dropdown
      @charge_accounts = projects_charge_accounts(@projects)
      # @stores = stores_dropdown
      @suppliers = suppliers_dropdown
      @payment_methods = payment_methods_dropdown
      @receipt_notes = []
      @purchase_orders = []
      @note_items = []
      @order_items = []
      @products = []
      # Special to approvals
      @users = User.where('id = ?', current_user.id)
      @companies = companies_dropdown

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @supplier_invoice }
      end
    end

    # GET /supplier_invoices/1/edit
    def edit
      @breadcrumb = 'update'
      @supplier_invoice = SupplierInvoice.find(params[:id])
      $attachment_changed = false
      $attachment = Attachment.new
      destroy_attachment
      # _form ivars
      @projects = projects_dropdown_edit(@supplier_invoice.project)
      # @search_projects = @projects.map{ |p| p.id }.map(&:inspect).join(',')
      @work_orders = @supplier_invoice.project.blank? ? work_orders_dropdown : @supplier_invoice.project.work_orders.order(:order_no)
      @charge_accounts = work_order_charge_account(@supplier_invoice)
      # @stores = work_order_store(@supplier_invoice)
      @suppliers = suppliers_dropdown
      @payment_methods = @supplier_invoice.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@supplier_invoice.organization_id)
      @receipt_notes = @supplier_invoice.supplier.blank? ? receipts_dropdown : receipts_dropdown_by_supplier(@supplier_invoice.supplier)
      @purchase_orders = @supplier_invoice.supplier.blank? ? unbilled_purchase_orders_dropdown : unbilled_purchase_orders_dropdown_by_supplier(@supplier_invoice.supplier)
      @note_items = []
      @order_items = []
      @products = []
      # @note_items = @supplier_invoice.receipt_note.blank? ? [] : note_items_dropdown(@supplier_invoice.receipt_note)
      # if @note_items.blank?
      #   @products = @supplier_invoice.organization.blank? ? products_dropdown : @supplier_invoice.organization.products(:product_code)
      # else
      #   @products = @note_items.first.receipt_note.products.group(:product_code)
      # end
      # Special to approvals
      @invoice_debt = number_with_precision(@supplier_invoice.debt.round(4), precision: 4)
      @invoice_not_yet_approved = number_with_precision(@supplier_invoice.amount_not_yet_approved.round(4), precision: 4)
      @users = User.where('id = ?', current_user.id)
      @is_approver = company_approver(@supplier_invoice, @supplier_invoice.project.company, current_user.id) ||
                     office_approver(@supplier_invoice, @supplier_invoice.project.office, current_user.id) ||
                     zone_approver(@supplier_invoice, @supplier_invoice.project.office.zone, current_user.id) ||
                     (current_user.has_role? :Approver)
      @companies = @supplier_invoice.organization.blank? ? companies_dropdown : companies_dropdown_edit(@supplier_invoice.organization)
    end

    # POST /supplier_invoices
    # POST /supplier_invoices.json
    def create
      @breadcrumb = 'create'
      @supplier_invoice = SupplierInvoice.new(params[:supplier_invoice])
      @supplier_invoice.created_by = current_user.id if !current_user.nil?
      # Should use attachment from drag&drop?
      if @supplier_invoice.attachment.blank? && !$attachment.avatar.blank?
        @supplier_invoice.attachment = $attachment.avatar
      end

      respond_to do |format|
        $attachment_changed = false
        if @supplier_invoice.save
          $attachment.destroy
          $attachment = nil
          format.html { redirect_to @supplier_invoice, notice: crud_notice('created', @supplier_invoice) }
          format.json { render json: @supplier_invoice, status: :created, location: @supplier_invoice }
        else
          $attachment.destroy
          $attachment = Attachment.new
          @projects = projects_dropdown
          # @search_projects = @projects.map{ |p| p.id }.map(&:inspect).join(',')
          @work_orders = work_orders_dropdown
          @charge_accounts = projects_charge_accounts(@projects)
          # @stores = stores_dropdown
          @suppliers = suppliers_dropdown
          @payment_methods = payment_methods_dropdown
          @receipt_notes = receipts_dropdown
          @purchase_orders = unbilled_and_undelivered_purchase_orders_dropdown
          # @receipt_notes = []
          # @purchase_orders = []
          @note_items = []
          @order_items = []
          @products = []
          @users = User.where('id = ?', current_user.id)
          @companies = companies_dropdown
          format.html { render action: "new" }
          format.json { render json: @supplier_invoice.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /supplier_invoices/1
    # PUT /supplier_invoices/1.json
    def update
      @breadcrumb = 'update'
      @supplier_invoice = SupplierInvoice.find(params[:id])

      master_changed = false
      # Should use attachment from drag&drop?
      if $attachment != nil && !$attachment.avatar.blank? && $attachment.updated_at > @supplier_invoice.updated_at
        @supplier_invoice.attachment = $attachment.avatar
      end
      if @supplier_invoice.attachment.dirty? || $attachment_changed
        master_changed = true
      end

      items_changed = false
      if params[:supplier_invoice][:supplier_invoice_approvals_attributes]
        params[:supplier_invoice][:supplier_invoice_approvals_attributes].values.each do |new_item|
          current_item = SupplierInvoiceApproval.find(new_item[:id]) rescue nil
          if ((current_item.nil?) || (new_item[:_destroy] != "false") ||
             ((current_item.approver_id.to_i != new_item[:approver_id].to_i) ||
              (current_item.approval_date != new_item[:approval_date].to_date) ||
              (current_item.approved_amount.to_f != new_item[:approved_amount].to_f) ||
              (current_item.remarks != new_item[:remarks])))
            items_changed = true
            break
          end
        end
      end
      if !items_changed && params[:supplier_invoice][:supplier_invoice_items_attributes]
        params[:supplier_invoice][:supplier_invoice_items_attributes].values.each do |new_item|
          current_item = SupplierInvoiceItem.find(new_item[:id]) rescue nil
          if ((current_item.nil?) || (new_item[:_destroy] != "false") ||
             ((current_item.product_id.to_i != new_item[:product_id].to_i) ||
              (current_item.description != new_item[:description]) ||
              (current_item.code != new_item[:code]) ||
              (current_item.quantity.to_f != new_item[:quantity].to_f) ||
              (current_item.price.to_f != new_item[:price].to_f) ||
              (current_item.discount_pct.to_f != new_item[:discount_pct].to_f) ||
              (current_item.discount.to_f != new_item[:discount].to_f) ||
              (current_item.tax_type_id.to_i != new_item[:tax_type_id].to_i) ||
              (current_item.receipt_note_id.to_i != new_item[:receipt_note_id].to_i) ||
              (current_item.receipt_note_item_id.to_i != new_item[:receipt_note_item_id].to_i) ||
              (current_item.project_id.to_i != new_item[:project_id].to_i) ||
              (current_item.work_order_id.to_i != new_item[:work_order_id].to_i) ||
              (current_item.charge_account_id.to_i != new_item[:charge_account_id].to_i)))
            items_changed = true
            break
          end
        end
      end
      if ((params[:supplier_invoice][:organization_id].to_i != @supplier_invoice.organization_id.to_i) ||
          (params[:supplier_invoice][:project_id].to_i != @supplier_invoice.project_id.to_i) ||
          (params[:supplier_invoice][:invoice_no].to_s != @supplier_invoice.invoice_no) ||
          (params[:supplier_invoice][:invoice_date].to_date != @supplier_invoice.invoice_date) ||
          (params[:supplier_invoice][:supplier_id].to_i != @supplier_invoice.supplier_id.to_i) ||
          (params[:supplier_invoice][:receipt_note_id].to_i != @supplier_invoice.receipt_note_id.to_i) ||
          (params[:supplier_invoice][:work_order_id].to_i != @supplier_invoice.work_order_id.to_i) ||
          (params[:supplier_invoice][:charge_account_id].to_i != @supplier_invoice.charge_account_id.to_i) ||
          (params[:supplier_invoice][:payment_method_id].to_i != @supplier_invoice.payment_method_id.to_i) ||
          (params[:supplier_invoice][:withholding].to_f != @supplier_invoice.withholding.to_f) ||
          (params[:supplier_invoice][:discount_pct].to_f != @supplier_invoice.discount_pct.to_f) ||
          (params[:supplier_invoice][:internal_no].to_s != @supplier_invoice.internal_no) ||
          (params[:supplier_invoice][:payday_limit].to_s != @supplier_invoice.payday_limit) ||
          (params[:supplier_invoice][:posted_at].to_s != @supplier_invoice.posted_at) ||
          (params[:supplier_invoice][:remarks].to_s != @supplier_invoice.remarks))
        master_changed = true
      end

      respond_to do |format|
        if master_changed || items_changed
          @supplier_invoice.updated_by = current_user.id if !current_user.nil?
          $attachment_changed = false
          if @supplier_invoice.update_attributes(params[:supplier_invoice])
            destroy_attachment
            $attachment = nil
            format.html { redirect_to @supplier_invoice,
                          notice: (crud_notice('updated', @supplier_invoice) + "#{undo_link(@supplier_invoice)}").html_safe }
            format.json { head :no_content }
          else
            destroy_attachment
            $attachment = Attachment.new
            @projects = projects_dropdown_edit(@supplier_invoice.project)
            # @search_projects = @projects.map{ |p| p.id }.map(&:inspect).join(',')
            @work_orders = @supplier_invoice.project.blank? ? work_orders_dropdown : @supplier_invoice.project.work_orders.order(:order_no)
            @charge_accounts = work_order_charge_account(@supplier_invoice)
            # @stores = work_order_store(@supplier_invoice)
            @suppliers = suppliers_dropdown
            @payment_methods = @supplier_invoice.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@supplier_invoice.organization_id)
            @receipt_notes = @supplier_invoice.supplier.blank? ? receipts_dropdown : receipts_dropdown_by_supplier(@supplier_invoice.supplier)
            @purchase_orders = @supplier_invoice.supplier.blank? ? unbilled_purchase_orders_dropdown : unbilled_purchase_orders_dropdown_by_supplier(@supplier_invoice.supplier)
            @note_items = []
            @order_items = []
            @products = []
            # @note_items = @supplier_invoice.receipt_note.blank? ? [] : note_items_dropdown(@supplier_invoice.receipt_note)
            # if @note_items.blank?
            #   @products = @supplier_invoice.organization.blank? ? products_dropdown : @supplier_invoice.organization.products(:product_code)
            # else
            #   @products = @note_items.first.receipt_note.products.group(:product_code)
            # end
            # Special to approvals
            @invoice_debt = number_with_precision(@supplier_invoice.debt.round(4), precision: 4)
            @invoice_not_yet_approved = number_with_precision(@supplier_invoice.amount_not_yet_approved.round(4), precision: 4)
            @users = User.where('id = ?', current_user.id)
            @is_approver = company_approver(@supplier_invoice, @supplier_invoice.project.company, current_user.id) ||
                           office_approver(@supplier_invoice, @supplier_invoice.project.office, current_user.id) ||
                           (current_user.has_role? :Approver)
            @companies = @supplier_invoice.organization.blank? ? companies_dropdown : companies_dropdown_edit(@supplier_invoice.organization)
            format.html { render action: "edit" }
            format.json { render json: @supplier_invoice.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to @supplier_invoice }
          format.json { head :no_content }
        end
      end
    end

    # DELETE /supplier_invoices/1
    # DELETE /supplier_invoices/1.json
    def destroy
      @supplier_invoice = SupplierInvoice.find(params[:id])

      respond_to do |format|
        if @supplier_invoice.destroy
          format.html { redirect_to supplier_invoices_url,
                      notice: (crud_notice('destroyed', @supplier_invoice) + "#{undo_link(@supplier_invoice)}").html_safe }
          format.json { head :no_content }
        else
          format.html { redirect_to supplier_invoices_url, alert: "#{@supplier_invoice.errors[:base].to_s}".gsub('["', '').gsub('"]', '') }
          format.json { render json: @supplier_invoice.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def destroy_attachment
      if $attachment != nil
        $attachment.destroy
      end
    end

    def current_projects_for_index(_projects)
      _current_projects = []
      _projects.each do |i|
        _current_projects = _current_projects << i.id
      end
      _current_projects
    end

    def inverse_no_search(no)
      _numbers = []
      # Add numbers found
      SupplierInvoice.where('invoice_no LIKE ?', "#{no}").each do |i|
        _numbers = _numbers << i.invoice_no
      end
      _numbers = _numbers.blank? ? no : _numbers
    end

    # Stores belonging to selected project
    def project_stores(_project)
      _array = []
      _stores = nil

      # Adding stores belonging to current project only
      # Stores with exclusive office
      if !_project.company.blank? && !_project.office.blank?
        _stores = Store.where("(company_id = ? AND office_id = ?)", _project.company.id, _project.office.id)
      elsif !_project.company.blank? && _project.office.blank?
        _stores = Store.where("(company_id = ?)", _project.company.id)
      elsif _project.company.blank? && !_project.office.blank?
        _stores = Store.where("(office_id = ?)", _project.office.id)
      else
        _stores = nil
      end
      ret_array(_array, _stores, 'id')
      # Stores with multiple offices
      if !_project.office.blank?
        _stores = StoreOffice.where("office_id = ?", _project.office.id)
        ret_array(_array, _stores, 'store_id')
      end

      # Returning founded stores
      _stores = Store.where(id: _array).order(:name)
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

    def receipts_dropdown
      if session[:office] != '0'
        ReceiptNote.unbilled_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        ReceiptNote.unbilled_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? ReceiptNote.unbilled(session[:organization].to_i, true) : ReceiptNote.unbilled(nil, true)
      end
    end

    def receipts_dropdown_by_project(_project)
      ReceiptNote.unbilled_by_project(_project.id, true)
    end

    def receipts_dropdown_by_supplier(_supplier)
      if session[:office] != '0'
        _supplier.receipt_notes.unbilled_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        _supplier.receipt_notes.unbilled_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? _supplier.receipt_notes.unbilled(session[:organization].to_i, true) : _supplier.receipt_notes.unbilled(nil, true)
      end
    end

    def receipts_dropdown_by_project_supplier(_project, _supplier)
      ReceiptNote.unbilled_by_project_supplier(_project.id, _supplier.id, true)
    end

    def note_items_dropdown(_note)
      _note.receipt_note_items.joins(:receipt_note_item_balance).where('receipt_note_item_balances.balance > ?', 0)
    end

    def purchase_orders_dropdown
      if session[:office] != '0'
        PurchaseOrder.undelivered_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        PurchaseOrder.undelivered_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? PurchaseOrder.undelivered(session[:organization].to_i, true) : PurchaseOrder.undelivered(nil, true)
      end
    end

    def purchase_orders_dropdown_by_supplier(_supplier)
      if session[:office] != '0'
        _supplier.purchase_orders.undelivered_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        _supplier.purchase_orders.undelivered_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? _supplier.purchase_orders.undelivered(session[:organization].to_i, true) : _supplier.receipt_notes.undelivered(nil, true)
      end
    end

    def unbilled_purchase_orders_dropdown
      if session[:office] != '0'
        PurchaseOrder.unbilled_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        PurchaseOrder.unbilled_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? PurchaseOrder.unbilled(session[:organization].to_i, true) : PurchaseOrder.unbilled(nil, true)
      end
    end

    def unbilled_purchase_orders_dropdown_by_project(_project)
      PurchaseOrder.unbilled_by_project(_project.id, true)
    end

    def unbilled_purchase_orders_dropdown_by_supplier(_supplier)
      if session[:office] != '0'
        _supplier.purchase_orders.unbilled_by_office(session[:office].to_i, true)
      elsif session[:company] != '0'
        _supplier.purchase_orders.unbilled_by_company(session[:company].to_i, true)
      else
        session[:organization] != '0' ? _supplier.purchase_orders.unbilled(session[:organization].to_i, true) : _supplier.purchase_orders.unbilled(nil, true)
      end
    end

    def unbilled_purchase_orders_dropdown_by_project_supplier(_project, _supplier)
      PurchaseOrder.unbilled_by_project_supplier(_project.id, _supplier.id, true)
    end

    def unbilled_and_undelivered_purchase_orders_dropdown
      if session[:office] != '0'
        PurchaseOrder.approved_unbilled_and_undelivered(nil, nil, session[:office].to_i, nil)
      elsif session[:company] != '0'
        PurchaseOrder.approved_unbilled_and_undelivered(nil, session[:company].to_i, nil, nil)
      elsif session[:organization] != '0'
        PurchaseOrder.approved_unbilled_and_undelivered(session[:organization].to_i, nil, nil, nil)
      else
        PurchaseOrder.approved_unbilled_and_undelivered(nil, nil, nil, nil)
      end
    end

    def unbilled_and_undelivered_purchase_orders_dropdown_by_project(_project)
      PurchaseOrder.approved_unbilled_and_undelivered(nil, nil, nil, _project.id)
    end

    def unbilled_and_undelivered_purchase_orders_dropdown_by_supplier(_supplier)
      if session[:office] != '0'
        _supplier.purchase_orders.approved_unbilled_and_undelivered(nil, nil, session[:office].to_i, nil)
      elsif session[:company] != '0'
        _supplier.purchase_orders.approved_unbilled_and_undelivered(nil, session[:company].to_i, nil, nil)
      elsif session[:organization] != '0'
        _supplier.purchase_orders.approved_unbilled_and_undelivered(session[:organization].to_i, nil, nil, nil)
      else
        _supplier.purchase_orders.approved_unbilled_and_undelivered(nil, nil, nil, nil)
      end
    end

    def unbilled_and_undelivered_purchase_orders_dropdown_by_project_supplier(_project, _supplier)
      _supplier.purchase_orders.approved_unbilled_and_undelivered(nil, nil, nil, _project.id)
    end

    def order_items_dropdown(_order)
      _order.purchase_order_items.joins(:purchase_order_item_balance).where('purchase_order_item_balances.balance > ?', 0)
    end

    def unbilled_order_items_dropdown(_order)
      _order.purchase_order_items.joins(:purchase_order_item_invoiced_balance).where('purchase_order_item_invoiced_balances.balance > ?', 0)
    end

    def charge_accounts_dropdown
      session[:organization] != '0' ? ChargeAccount.expenditures.where(organization_id: session[:organization].to_i) : ChargeAccount.expenditures
    end

    def charge_accounts_dropdown_edit(_project)
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

    def companies_dropdown
      if session[:company] != '0'
        _companies = Company.where(id: session[:company].to_i)
      else
        _companies = session[:organization] != '0' ? Company.where(organization_id: session[:organization].to_i).order(:name) : Company.order(:name)
      end
    end

    def companies_dropdown_edit(_organization)
      if session[:company] != '0'
        _companies = Company.where(id: session[:company].to_i)
      else
        _companies = _organization.companies.order(:name)
      end
    end

    def notes_array(_notes)
      _array = []
      _notes.each do |i|
        _array = _array << [i.id, i.receipt_no, formatted_date(i.receipt_date), i.supplier.full_name]
      end
      _array
    end

    def note_items_array(_note_items)
      _array = []
      _note_items.each do |i|
        _array = _array << [ i.id, i.id.to_s + ":", i.product.full_code, i.description[0,20],
                           (!i.quantity.blank? ? formatted_number(i.quantity, 4) : formatted_number(0, 4)),
                           (!i.net_price.blank? ? formatted_number(i.net_price, 4) : formatted_number(0, 4)),
                           (!i.amount.blank? ? formatted_number(i.amount, 4) : formatted_number(0, 4)),
                           "(" + (!i.balance.blank? ? formatted_number(i.balance, 4) : formatted_number(0, 4)) + ")" ]
      end
      _array
    end

    def products_array(_products)
      _array = []
      _products.each do |i|
        _array = _array << [i.id, i.full_code, i.main_description[0,40]]
      end
      _array
    end

    # Work orders array
    def work_orders_array(_orders)
      _array = []
      _orders.each do |i|
        _array = _array << [i.id, i.full_name]
      end
      _array
    end

    # Purchase orders array
    def purchase_orders_array(_orders)
      _array = []
      _orders.each do |i|
        _array = _array << [i.id, i.full_no, formatted_date(i.order_date), i.supplier.full_name]
      end
      _array
    end

    def order_items_array(_order_items)
      _array = []
      _order_items.each do |i|
        _array = _array << [ i.id, i.id.to_s + ":", i.product.full_code, i.description[0,20],
                           (!i.quantity.blank? ? formatted_number(i.quantity, 4) : formatted_number(0, 4)),
                           (!i.net_price.blank? ? formatted_number(i.net_price, 4) : formatted_number(0, 4)),
                           (!i.amount.blank? ? formatted_number(i.amount, 4) : formatted_number(0, 4)),
                           "(" + (!i.balance.blank? ? formatted_number(i.balance, 4) : formatted_number(0, 4)) + ")" ]
      end
      _array
    end

    # Returns _array from _ret table/model filled with _id attribute
    def ret_array(_array, _ret, _id)
      if !_ret.nil?
        _ret.each do |_r|
          _array = _array << _r.read_attribute(_id) unless _array.include? _r.read_attribute(_id)
        end
      end
    end

    # Use purchase price, if any. Otherwise, the reference price
    # _product is the instance variable @product
    # _supplier is a variable containing supplier_id
    def product_price_to_apply(_product, _supplier)
      _price = 0
      _discount_rate = 0
      _code = ""
      _purchase_price = PurchasePrice.find_by_product_and_supplier(_product.id, _supplier)
      if !_purchase_price.nil?
        _price = _purchase_price.price
        _discount_rate = _purchase_price.discount_rate
        _code = _purchase_price.code
      else
        _price = _product.reference_price
        _discount_rate = Supplier.find(_supplier).discount_rate rescue 0
      end
      return _price, _discount_rate, _code
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
    end

    def si_remove_filters
      params[:search] = ""
      params[:No] = ""
      params[:Supplier] = ""
      params[:Project] = ""
      params[:Order] = ""
      return " "
    end

    def si_restore_filters
      params[:search] = session[:search]
      params[:No] = session[:No]
      params[:Supplier] = session[:Supplier]
      params[:Project] = session[:Project]
      params[:Order] = session[:Order]
    end
  end
end
