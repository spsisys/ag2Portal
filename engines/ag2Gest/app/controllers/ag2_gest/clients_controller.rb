require_dependency "ag2_gest/application_controller"

module Ag2Gest
  class ClientsController < ApplicationController
    include IbanModule

    before_filter :authenticate_user!
    before_filter :set_defaults_for_new_and_edit, only: [:new, :edit]
    load_and_authorize_resource
    skip_load_and_authorize_resource :only => [:cl_update_textfields_from_organization,
                                               :update_province_textfield_from_town,
                                               :update_province_textfield_from_zipcode,
                                               :update_country_textfield_from_region,
                                               :update_region_textfield_from_province,
                                               :cl_generate_code,
                                               :et_validate_fiscal_id_textfield,
                                               :cl_validate_fiscal_id_textfield,
                                               :cl_update_office_select_from_bank,
                                               :cl_check_iban,
                                               :cl_validate_iban,
                                               :cl_load_dropdowns,
                                               :cl_load_debt,
                                               :check_client_depent_subscribers,
                                               :client_report]
    def client_report
      manage_filter_state
      letter = params[:letter]
      if !session[:organization]
        init_oco
      end

      @search = Client.search do
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !letter.blank? && letter != "%"
          any_of do
            #with(:last_name).starting_with(letter)
            with(:full_name).starting_with(letter)
            with(:company).starting_with(letter)
          end
        end
        order_by :sort_no, :asc
        paginate :page => params[:page] || 1, :per_page => Client.count
      end
      client_ids = []
      @search.hits.each do |i|
        client_ids << i.result.id
      end
      @clients = Client.with_these_ids(client_ids)

      # @clients = @search.results
      title = t("activerecord.models.client.few")
      respond_to do |format|
        # Render PDF
        format.pdf { send_data render_to_string,
                    filename: "#{title}.pdf",
                    type: 'application/pdf',
                    disposition: 'inline' }
        format.csv { send_data Client.to_client_csv(@clients),
                     filename: "#{title}.csv",
                     type: 'application/csv',
                     disposition: 'inline' }
      end
    end

    # Update office select at view from bank select
    def cl_update_office_select_from_bank
      bank = params[:bank]
      if bank != '0'
        @bank = Bank.find(bank)
        @offices = @bank.blank? ? bank_offices_array : bank_offices_array(@bank)
      else
        @offices = bank_offices_array
      end
      # Setup JSON
      @json_data = { "office" => @offices }
      render json: @json_data
    end

    # Check IBAN
    def cl_check_iban
      iban = check_iban(params[:country], params[:dc], params[:bank], params[:office], params[:account])
      # Setup JSON
      @json_data = { "iban" => iban }
      render json: @json_data
    end

    # Validate IBAN
    def cl_validate_iban
      invalidIBAN = I18n.t("activerecord.errors.models.client_bank_account.iban_invalid")
      tryAgain = I18n.t("should_try_again")
      valid = iban_valid?(params[:iban])
      # Setup JSON
      @json_data = { "valid" => valid, "iban" => params[:iban],
                     "invalidIBAN" => invalidIBAN, "tryAgain" => tryAgain }
      render json: @json_data
    end

    # not desactive client if client.subscribers.count > 0
    def check_client_depent_subscribers
      client_id = params[:id]
      @client = Client.find(client_id)
      @subscriber = @client.subscribers.activated.count
      @json_data = { "subscriber_count" => @subscriber }

      respond_to do |format|
        format.html #
        format.json { render json: @json_data }
      end
    end

    # Update payment method and ledger account text fields at view from organization select
    def cl_update_textfields_from_organization
      organization = params[:org]
      if organization != '0'
        @organization = Organization.find(organization)
        @payment_methods = @organization.blank? ? payment_methods_dropdown : payment_payment_methods(@organization.id)
        @ledger_accounts = @organization.blank? ? ledger_accounts_dropdown : @organization.ledger_accounts.order(:code)
      else
        @payment_methods = payment_methods_dropdown
        @ledger_accounts = ledger_accounts_dropdown
      end
      # Ledger accounts array
      @ledger_accounts_dropdown = ledger_accounts_array(@ledger_accounts)
      # Setup JSON
      @json_data = { "payment_method" => @payment_methods, "accounts" => @ledger_accounts_dropdown }
      render json: @json_data
    end

    # Update country text field at view from region select
    def update_country_textfield_from_region
      @region = Region.find(params[:id])
      @country = Country.find(@region.country)

      respond_to do |format|
        format.html # update_country_textfield_from_region.html.erb does not exist! JSON only
        format.json { render json: @country }
      end
    end

    # Update region and country text fields at view from town select
    def update_region_textfield_from_province
      @province = Province.find(params[:id])
      @region = Region.find(@province.region)
      @country = Country.find(@region.country)
      @json_data = { "region_id" => @region.id, "country_id" => @country.id }

      respond_to do |format|
        format.html # update_province_textfield.html.erb does not exist! JSON only
        format.json { render json: @json_data }
      end
    end

    # Update province, region and country text fields at view from town select
    def update_province_textfield_from_town
      @town = Town.find(params[:id])
      @province = Province.find(@town.province)
      @region = Region.find(@province.region)
      @country = Country.find(@region.country)
      @json_data = { "province_id" => @province.id, "region_id" => @region.id, "country_id" => @country.id }

      respond_to do |format|
        format.html # update_province_textfield.html.erb does not exist! JSON only
        format.json { render json: @json_data }
      end
    end

    # Update town, province, region and country text fields at view from zipcode select
    def update_province_textfield_from_zipcode
      @zipcode = Zipcode.find(params[:id])
      @town = Town.find(@zipcode.town)
      @province = Province.find(@town.province)
      @region = Region.find(@province.region)
      @country = Country.find(@region.country)
      @json_data = { "town_id" => @town.id, "province_id" => @province.id, "region_id" => @region.id, "country_id" => @country.id }

      respond_to do |format|
        format.html # update_province_textfield.html.erb does not exist! JSON only
        format.json { render json: @json_data }
      end
    end

    # Update client code at view (generate_code_btn)
    def cl_generate_code
      organization = params[:id]

      # Builds code, if possible
      code = organization == '$' ? '$err' : cl_next_code(organization)
      @json_data = { "code" => code }
      render json: @json_data
    end

    # Search Entity
    def cl_validate_fiscal_id_textfield
      id = ''
      fiscal_id = ''
      name = ''
      first_name = ''
      last_name = ''
      company = ''
      street_type_id = ''
      street_name = ''
      street_number = ''
      building = ''
      floor = ''
      floor_office = ''
      zipcode_id = ''
      town_id = ''
      province_id = ''
      region_id = ''
      country_id = ''
      phone = ''
      fax = ''
      cellular = ''
      email = ''
      organization_id = ''
      entity_type = ''
      code = ''

      if params[:id] == '0'
        id = '$err'
        fiscal_id = '$err'
      else
        if session[:organization] != '0'
          @entity = Entity.find_by_fiscal_id_and_organization(params[:id], session[:organization])
        else
          @entity = Entity.find_by_fiscal_id(params[:id])
        end
        if @entity.nil?
          id = '$err'
          fiscal_id = '$err'
        else
          id = @entity.id
          fiscal_id = @entity.fiscal_id
          entity_type = @entity.entity_type_id
          if @entity.entity_type_id < 2
            first_name = @entity.first_name
            last_name = @entity.last_name
            name = @entity.full_name
          else
            company = @entity.company
            name = @entity.company
          end
          street_type_id = @entity.street_type_id
          street_name = @entity.street_name
          street_number = @entity.street_number
          building = @entity.building
          floor = @entity.floor
          floor_office = @entity.floor_office
          zipcode_id = @entity.zipcode_id
          town_id = @entity.town_id
          province_id = @entity.province_id
          region_id = @entity.region_id
          country_id = @entity.country_id
          phone = @entity.phone
          fax = @entity.fax
          cellular = @entity.cellular
          email = @entity.email
          organization_id = @entity.organization_id
          # Must check if already exist
          if !Client.find_by_fiscal_id(params[:id]).nil?
            code = I18n.t("activerecord.errors.models.client.already_exists")
          end
        end
      end

      @json_data = { "id" => id, "fiscal_id" => fiscal_id, "name" => name,
                     "street_type_id" => street_type_id, "street_name" => street_name,
                     "street_number" => street_number, "building" => building,
                     "floor" => floor, "floor_office" => floor_office,
                     "zipcode_id" => zipcode_id, "town_id" => town_id,
                     "province_id" => province_id, "region_id" => region_id,
                     "country_id" => country_id, "phone" => phone,
                     "fax" => fax, "cellular" => cellular, "email" => email,
                     "organization_id" => organization_id, "company" => company,
                     "first_name" => first_name, "last_name" => last_name,
                     "entity_type" => entity_type, "code" => code }

      respond_to do |format|
        format.html # validate_fiscal_id_textfield.html.erb does not exist! JSON only
        format.json { render json: @json_data }
      end
    end

    # Validate entity fiscal id (modal)
    def et_validate_fiscal_id_textfield
      fiscal_id = params[:id]
      dc = ''
      f_id = 'OK'
      f_name = ''

      if fiscal_id == '0'
        f_id = '$err'
      else
        dc = fiscal_id_dc(fiscal_id)
        if dc == '$par' || dc == '$err'
          f_id = '$err'
        else
          if dc == '$uni'
            f_id = '??'
          end
          f_name = fiscal_id_description(fiscal_id[0])
          if f_name == '$err'
            f_name = I18n.t("ag2_admin.entities.fiscal_name")
          end
        end
      end

      @json_data = { "fiscal_id" => f_id, "fiscal_name" => f_name }
      render json: @json_data
    end

    #*** Charge modal dropdowns async ***
    def cl_load_dropdowns
      client = Client.find(params[:client_id])
      current_debt = number_with_precision(client.total_existing_debt, precision: 2, delimiter: I18n.locale == :es ? "." : ",")
      current_debt_label = I18n.t('activerecord.attributes.client.debt') + ':'

      @json_data = { "current_debt" => current_debt, "current_debt_label" => current_debt_label }
      render json: @json_data
    end

    def cl_load_debt
      client = Client.find(params[:client_id])
      current_debt = number_with_precision(client.total_existing_debt, precision: 2, delimiter: I18n.locale == :es ? "." : ",")
      current_debt_label = I18n.t('activerecord.attributes.client.debt') + ':'
      @json_data = { "current_debt" => current_debt, "current_debt_label" => current_debt_label }
      render json: @json_data
    end

    #
    # Default Methods
    #
    # GET /suppliers
    # GET /suppliers.json
    def index
      manage_filter_state
      letter = params[:letter]
      if !session[:organization]
        init_oco
      end

      @search = Client.search do
        fulltext params[:search]
        if session[:organization] != '0'
          with :organization_id, session[:organization]
        end
        if !letter.blank? && letter != "%"
          any_of do
            #with(:last_name).starting_with(letter)
            with(:full_name).starting_with(letter)
            with(:company).starting_with(letter)
          end
        end
        order_by :sort_no, :asc
        paginate :page => params[:page] || 1, :per_page => per_page
      end
      @clients = @search.results

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @clients }
        format.js
      end
    end

    # GET /clients/1
    # GET /clients/1.json
    def show
      @breadcrumb = 'read'
      @client = Client.find(params[:id])
      @subscribers = @client.subscribers.by_code
                     .includes(:zipcode, street_directory: [:street_type, town: [province: [region: :country]]])
                     .paginate(:page => params[:page] || 1, :per_page => per_page || 10)
      @bills = @client.bills.not_service
              .includes(invoices: [:biller, :invoice_type, :invoice_status, :invoice_operation, invoice_items: :tax_type])
              .paginate(:page => params[:page] || 1, :per_page => per_page || 10)
      @accounts = ClientBankAccount.by_client_full(@client.id)
                  .paginate(:page => params[:page] || 1, :per_page => per_page || 10)
      @current_debt = @client.current_debt
      @payment_methods = []
      @ledger_accounts = []
      @classes = []
      @banks = []
      @offices = []
      @towns = []
      @provinces = []
      @zipcodes = []
      @regions = []
      @countries = []

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @client }
      end
    end

    # GET /clients/new
    # GET /clients/new.json
    def new
      @breadcrumb = 'create'
      @client = Client.new
      @payment_methods = payment_methods_dropdown

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @client }
      end
    end

    # GET /clients/1/edit
    def edit
      @breadcrumb = 'update'
      @client = Client.find(params[:id])
      @payment_methods = @client.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@client.organization_id)
    end

    # POST /clients
    # POST /clients.json
    def create
      @breadcrumb = 'create'
      @client = Client.new(params[:client])
      @client.created_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @client.save
          format.html { redirect_to @client, notice: crud_notice('created', @client) }
          format.json { render json: @client, status: :created, location: @client }
        else
          set_defaults_for_new_and_edit()
          @payment_methods = payment_methods_dropdown
          format.html { render action: "new" }
          format.json { render json: @client.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /clients/1
    # PUT /clients/1.json
    def update
      @breadcrumb = 'update'
      @client = Client.find(params[:id])
      @client.updated_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @client.update_attributes(params[:client])
          format.html { redirect_to @client,
                        notice: (crud_notice('updated', @client) + "#{undo_link(@client)}").html_safe }
          format.json { head :no_content }
        else
          set_defaults_for_new_and_edit()
          @payment_methods = @client.organization.blank? ? payment_methods_dropdown : payment_payment_methods(@client.organization_id)
          format.html { render action: "edit" }
          format.json { render json: @client.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /clients/1
    # DELETE /clients/1.json
    def destroy
      @client = Client.find(params[:id])

      respond_to do |format|
        if @client.destroy
          format.html { redirect_to clients_url,
                      notice: (crud_notice('destroyed', @client) + "#{undo_link(@client)}").html_safe }
          format.json { head :no_content }
        else
          format.html { redirect_to clients_url, alert: "#{@client.errors[:base].to_s}".gsub('["', '').gsub('"]', '') }
          format.json { render json: @client.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    # Filters
    def set_empty_defaults_for_new_and_edit
      @street_types = []
      @ledger_accounts = []
      @towns = []
      @provinces = []
      @zipcodes = []
      @regions = []
      @countries = []
      @banks = []
      @offices = []
      @classes = []
    end

    def set_defaults_for_new_and_edit
      @street_types = street_types_array
      @ledger_accounts = ledger_accounts_dropdown
      @towns = towns_array
      @provinces = provinces_array
      @zipcodes = zipcodes_array
      @regions = regions_array
      @countries = country_array
      # @banks = banks_array
      # @offices = bank_offices_array
      @classes = bank_account_classes_array
    end

    def street_types_dropdown
      StreetType.order(:street_type_code) \
                .select("id, CONCAT(street_type_code, ' (', street_type_description, ')') to_label_")
    end

    def bank_account_classes_dropdown
      BankAccountClass.order(:name) \
                      .select("id, name to_label_")
      # BankAccountClass.all(order: 'name')
    end

    def banks_dropdown
      Bank.order(:code) \
          .select("id, CONCAT(code, ' ', name) to_label_")
      # Bank.order(:code)
    end

    def bank_offices_dropdown(_bank=nil)
      if _bank.nil?
        BankOffice.order('bank_offices.bank_id, bank_offices.code').joins(:bank)
                  .select("bank_offices.id, CONCAT(bank_offices.code, ' ', bank_offices.name, ' (', banks.code, ')') to_label_")
      else
        BankOffice.order('bank_offices.bank_id, bank_offices.code').joins(:bank)
                  .select("bank_offices.id, CONCAT(bank_offices.code, ' ', bank_offices.name, ' (', banks.code, ')') to_label_")
                  .where("bank_offices.bank_id = ?", _bank)
      end
      # BankOffice.order(:bank_id, :code).includes(:bank,:country)
    end

    def towns_dropdown
      Town.order('towns.name').joins(:province) \
          .select("towns.id, CONCAT(towns.name, ' (', provinces.name, ')') to_label_")
      # Town.order(:name).includes(:province)
    end

    def provinces_dropdown
      Province.order('provinces.name').joins(:region)
              .select("provinces.id, CONCAT(provinces.name, ' (', regions.name, ')') to_label_")
      # Province.order(:name).includes(:region)
    end

    def zipcodes_dropdown
      Zipcode.order(:zipcode).joins(:town, :province) \
             .select("zipcodes.id, CONCAT(zipcodes.zipcode, ' - ', towns.name, ' (', provinces.name, ')') to_label_")
      # Zipcode.order(:zipcode).includes(:town,:province)
    end

    def regions_dropdown
      Region.order('regions.name').joins(:country) \
            .select("regions.id, CONCAT(regions.name, ' (', countries.name, ')') to_label_")
    end

    def countries_dropdown
      Country.order(:name) \
             .select("id, CONCAT(code, ' ', name) to_label_")
      # Country.order(:code)
    end

    def street_types_array
      _street_types = street_types_dropdown
      _array = []
      _street_types.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def banks_array
      _banks = banks_dropdown
      _array = []
      _banks.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def bank_offices_array(_bank=nil)
      _bank_offices = bank_offices_dropdown(_bank)
      _array = []
      _bank_offices.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def bank_account_classes_array
      _bac = bank_account_classes_dropdown
      _array = []
      _bac.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def towns_array
      _towns = towns_dropdown
      _array = []
      _towns.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def provinces_array
      _provinces = provinces_dropdown
      _array = []
      _provinces.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def zipcodes_array
      _zipcodes = zipcodes_dropdown
      _array = []
      _zipcodes.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def regions_array
      _regions = regions_dropdown
      _array = []
      _regions.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    def country_array
      _country = countries_dropdown
      _array = []
      _country.each do |i|
        _array = _array << [i.id, i.to_label_]
      end
      _array
    end

    # Ledger accounts belonging to projects
    def projects_ledger_accounts(_projects)
      _array = []
      _ret = nil

      # Adding ledger accounts belonging to current projects
      _projects.each do |i|
        _ret = LedgerAccount.where(project_id: i.id)
        ret_array(_array, _ret, 'id')
      end

      # Adding global ledger accounts belonging to projects organizations
      _sort_projects_by_organization = _projects.sort { |a,b| a.organization_id <=> b.organization_id }
      _previous_organization = _sort_projects_by_organization.first.organization_id
      _sort_projects_by_organization.each do |i|
        if _previous_organization != i.organization_id
          # when organization changes, process previous
          _ret = LedgerAccount.where('(project_id IS NULL AND ledger_accounts.organization_id = ?)', _previous_organization)
          ret_array(_array, _ret, 'id')
          _previous_organization = i.organization_id
        end
      end
      # last organization, process previous
      _ret = LedgerAccount.where('(project_id IS NULL AND ledger_accounts.organization_id = ?)', _previous_organization)
      ret_array(_array, _ret, 'id')

      # Returning founded ledger accounts
      _ret = LedgerAccount.where(id: _array).order(:code)
    end

    def projects_dropdown
      _projects = nil
      _oco = false
      if session[:office] != '0'
        _projects = Project.active_only.where(office_id: session[:office].to_i)
        _oco = true
      elsif session[:company] != '0'
        _projects = Project.active_only.where(company_id: session[:company].to_i)
        _oco = true
      elsif session[:organization] != '0'
        _projects = Project.active_only.where(organization_id: session[:organization].to_i)
        _oco = true
      end
      return _projects, _oco
    end

    def payment_methods_dropdown
      session[:organization] != '0' ? payment_payment_methods(session[:organization].to_i) : payment_payment_methods(0)
    end

    def payment_payment_methods(_organization=0)
      if _organization != 0
        PaymentMethod.collections_belong_to_organization(_organization).select("id, description")
      else
        PaymentMethod.collections.select("id, description")
      end
    end

    def ledger_accounts_dropdown
      _projects, _oco = projects_dropdown
      if _oco == false
        LedgerAccount.order(:code)
      else
        if _projects.blank?
          session[:organization] != '0' ? LedgerAccount.where(organization_id: session[:organization].to_i).order(:code) : LedgerAccount.order(:code)
        else
          projects_ledger_accounts(_projects)
        end
      end
    end

    def ledger_accounts_array(_accounts)
      _array = []
      _accounts.each do |i|
        _array = _array << [i.id, i.full_name]
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

    # Keeps filter state
    def manage_filter_state
      # search
      if params[:search]
        session[:search] = params[:search]
      elsif session[:search]
        params[:search] = session[:search]
      end
      # letter
      if params[:letter]
        if params[:letter] == '%'
          session[:letter] = nil
          params[:letter] = nil
        else
          session[:letter] = params[:letter]
        end
      elsif session[:letter]
        params[:letter] = session[:letter]
      end
    end
  end
end
