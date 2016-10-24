require_dependency "ag2_gest/application_controller"

module Ag2Gest
  class TariffSchemesController < ApplicationController

    before_filter :authenticate_user!
    load_and_authorize_resource
    skip_load_and_authorize_resource :only => [:create_pct, :simple_edit]
    helper_method :sort_column

    # GET /tariff_schemes
    # GET /tariff_schemes.json
    def index
      manage_filter_state
      @project_ids = current_projects_ids
      @search = TariffScheme.search do
        with :project_id, current_projects_ids
        if !params[:search].blank?
          fulltext params[:search]
        end
        order_by sort_column, sort_direction
        paginate :page => params[:page] || 1, :per_page => per_page
      end

      @tariff_schemes = @search.results

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @tariff_schemes }
        format.js
      end
    end

    # GET /tariff_schemes/1
    # GET /tariff_schemes/1.json
    def show
      @breadcrumb = 'read'
      @tariff_scheme = TariffScheme.find(params[:id])

      #Call Method Model, group if contains any tariff_active
      @tariffs = @tariff_scheme.contain_tariffs_active

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @tariff_scheme }
      end
    end

    # GET /tariff_schemes/new
    # GET /tariff_schemes/new.json
    def new
      @breadcrumb = 'create'
      @tariff_scheme = TariffScheme.new
      @projects = current_projects

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @tariff_scheme }
      end
    end

    # GET /tariff_schemes/1/edit
    def edit
      @breadcrumb = 'update'
      @tariff_scheme = TariffScheme.find(params[:id])
      @billable_items = @tariff_scheme.project.billable_items.joins(:billable_concept).order("billable_concepts.billable_document")
      @caliber = Caliber.all
      @billable_items.each do |b|
        if b.tariffs_by_caliber
          @caliber.each do |c|
            @tariff_scheme.tariffs.build(tariff_type_id: @tariff_scheme.tariff_type_id, caliber_id: c.id, billable_item_id: b.id)
          end
        else
          @tariff_scheme.tariffs.build(tariff_type_id: @tariff_scheme.tariff_type_id, caliber_id: nil, billable_item_id: b.id)
        end
      end
    end

    def simple_edit
      @breadcrumb = 'update'
      @tariff_scheme = TariffScheme.find(params[:id])
      @projects = current_projects
      respond_to do |format|
        format.html # simple_edit.html.erb
        format.json { render json: @tariff_scheme }
      end
    end

    # POST /tariff_schemesf
    # POST /tariff_schemes.json
    def create
      @breadcrumb = 'create'
      @projects = current_projects
      @tariff_scheme = TariffScheme.new(params[:tariff_scheme])
      @tariff_scheme.created_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @tariff_scheme.save
          format.html { redirect_to edit_tariff_scheme_path(@tariff_scheme), notice: t('activerecord.attributes.tariff_scheme.create') }
          format.json { render json: @tariff_scheme, status: :created, location: @tariff_scheme }
        else
          format.html { render action: "new" }
          format.json { render json: @tariff_scheme.errors, status: :unprocessable_entity }
        end
      end
    end

    def create_pct
      @tariff_scheme_old = TariffScheme.find(params[:tariff_schemes])
      @tariff_scheme_new = TariffScheme.create(
        project_id: @tariff_scheme_old.project_id,
        name: @tariff_scheme_old.name,
        starting_at:  params[:init_date],
        ending_at: nil,
        tariff_type_id:@tariff_scheme_old.tariff_type_id,
        created_by: current_user.try(:id),
        updated_by: current_user.try(:id)
      )
      @tariff_scheme_old.tariffs.each do |tariff|
        Tariff.create(
          tariff_scheme_id: @tariff_scheme_new.id,
          billable_item_id: tariff.billable_item_id,
          tariff_type_id: tariff.tariff_type_id,
          caliber_id: tariff.caliber_id,
          billing_frequency_id: tariff.billing_frequency_id,
          fixed_fee: tariff.fixed_fee + (tariff.fixed_fee * (params["pct_value"].to_f / 100)),
          variable_fee: tariff.variable_fee + (tariff.variable_fee * (params["pct_value"].to_f / 100)),
          percentage_fee: tariff.percentage_fee + (tariff.percentage_fee * (params["pct_value"].to_f / 100)),
          percentage_applicable_formula: tariff.percentage_applicable_formula,
          block1_limit: tariff.block1_limit,
          block2_limit: tariff.block2_limit,
          block3_limit: tariff.block3_limit,
          block4_limit: tariff.block4_limit,
          block5_limit: tariff.block5_limit,
          block6_limit: tariff.block6_limit,
          block7_limit: tariff.block7_limit,
          block8_limit: tariff.block8_limit,
          block1_fee: tariff.block1_fee + (tariff.block1_fee * (params["pct_value"].to_f / 100)),
          block2_fee: tariff.block2_fee + (tariff.block2_fee * (params["pct_value"].to_f / 100)),
          block3_fee: tariff.block3_fee + (tariff.block3_fee * (params["pct_value"].to_f / 100)),
          block4_fee: tariff.block4_fee + (tariff.block4_fee * (params["pct_value"].to_f / 100)),
          block5_fee: tariff.block5_fee + (tariff.block5_fee * (params["pct_value"].to_f / 100)),
          block6_fee: tariff.block6_fee + (tariff.block6_fee * (params["pct_value"].to_f / 100)),
          block7_fee: tariff.block7_fee + (tariff.block7_fee * (params["pct_value"].to_f / 100)),
          block8_fee: tariff.block8_fee + (tariff.block8_fee * (params["pct_value"].to_f / 100)),
          discount_pct_f: tariff.discount_pct_f,
          discount_pct_v: tariff.discount_pct_v,
          discount_pct_p: tariff.discount_pct_p,
          discount_pct_b: tariff.discount_pct_b,
          tax_type_f_id: tariff.tax_type_f_id,
          tax_type_v_id: tariff.tax_type_v_id,
          tax_type_p_id: tariff.tax_type_p_id,
          tax_type_b_id: tariff.tax_type_b_id
        )
      end
      respond_to do |format|
        if @tariff_scheme_new.save
          @tariff_scheme_old.update_attributes(ending_at: params[:init_date])
          format.html { redirect_to tariff_schemes_path, notice: t('activerecord.attributes.tariff_scheme.create') }
          format.json { render json: @tariff_scheme_new, status: :created, location: @tariff_scheme_new }
        else
          format.html { render action: "index" }
          format.json { render json: @tariff_scheme_new.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /tariff_schemes/1
    # PUT /tariff_schemes/1.json
    def update
      @breadcrumb = 'update'
      @projects = current_projects
      @tariff_scheme = TariffScheme.find(params[:id])
      @tariff_scheme.updated_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @tariff_scheme.update_attributes(params[:tariff_scheme])
          format.html { redirect_to tariff_scheme_path(@tariff_scheme), notice: t('activerecord.attributes.tariff_scheme.successfully') }
          format.json { head :no_content }
        else
          format.html { redirect_to tariff_scheme_path(@tariff_scheme), alert: @tariff_scheme.errors }
          format.json { render json: @tariff_scheme.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /tariff_schemes/1
    # DELETE /tariff_schemes/1.json
    def destroy
      @tariff_scheme = TariffScheme.find(params[:id])
      @tariff_scheme.destroy

      respond_to do |format|
        format.html { redirect_to tariff_schemes_url }
        format.json { head :no_content }
      end
    end

    private

    def sort_column
      TariffScheme.column_names.include?(params[:sort]) ? params[:sort] : "name"
    end

    # Keeps filter state
    def manage_filter_state
      # search
      if params[:search]
        session[:search] = params[:search]
      elsif session[:search]
        params[:search] = session[:search]
      end
      # sort
      if params[:sort]
        session[:sort] = params[:sort]
      elsif session[:sort]
        params[:sort] = session[:sort]
      end
      # direction
      if params[:direction]
        session[:direction] = params[:direction]
      elsif session[:direction]
        params[:direction] = session[:direction]
      end
    end


  end
end
