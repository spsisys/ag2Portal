require_dependency "ag2_human/application_controller"

module Ag2Human
  class TimeRecordsController < ApplicationController
    before_filter :authenticate_user!
    load_and_authorize_resource
    # GET /time_records
    # GET /time_records.json
    def index
      manage_filter_state
      worker = params[:Worker]
      from = params[:From]
      to = params[:To]
      type = params[:Type]
      code = params[:Code]

      # Sunspot re-index is on ag2_timerecord_controller
      if session[:reindex] == true
        timerecord_reindex
        session[:reindex] = nil
      end

      @search = TimeRecord.search do
        if !worker.blank?
          with :worker_id, worker
        end
        if !from.blank?
          any_of do
            with(:timerecord_date).greater_than(from)
            with :timerecord_date, from
          end
        end
        if !to.blank?
          any_of do
            with(:timerecord_date).less_than(to)
            with :timerecord_date, to
          end
        end
        if !type.blank?
          with :timerecord_type_id, type
        end
        if !code.blank?
          with :timerecord_code_id, code
        end
        data_accessor_for(TimeRecord).include = [:worker, :timerecord_type, :timerecord_code]
        order_by :timerecord_date, :desc
        order_by :timerecord_time, :desc
        paginate :page => params[:page] || 1, :per_page => per_page
      end
      # @time_records = @search.results.sort_by{ |record| [ record.timerecord_date, record.timerecord_time ] }
      #@time_records = TimeRecord.paginate(:page => params[:page], :per_page => per_page).order(:timerecord_date, :timerecord_time)
      @time_records = @search.results

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @time_records }
        format.js
      end
    end

    # GET /time_records/1
    # GET /time_records/1.json
    def show
      @breadcrumb = 'read'
      @time_record = TimeRecord.find(params[:id])

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @time_record }
      end
    end

    # GET /time_records/new
    # GET /time_records/new.json
    def new
      @breadcrumb = 'create'
      @time_record = TimeRecord.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @time_record }
      end
    end

    # GET /time_records/1/edit
    def edit
      @breadcrumb = 'update'
      @time_record = TimeRecord.find(params[:id])
    end

    # POST /time_records
    # POST /time_records.json
    def create
      @breadcrumb = 'create'
      @time_record = TimeRecord.new(params[:time_record])
      @time_record.created_by = current_user.id if !current_user.nil?
      @time_record.source_ip = request.remote_ip

      respond_to do |format|
        if @time_record.save
          format.html { redirect_to @time_record, notice: crud_notice('created', @time_record) }
          format.json { render json: @time_record, status: :created, location: @time_record }
        else
          format.html { render action: "new" }
          format.json { render json: @time_record.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /time_records/1
    # PUT /time_records/1.json
    def update
      @breadcrumb = 'update'
      @time_record = TimeRecord.find(params[:id])
      @time_record.updated_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @time_record.update_attributes(params[:time_record])
          format.html { redirect_to @time_record,
                        notice: (crud_notice('updated', @time_record) + "#{undo_link(@time_record)}").html_safe }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @time_record.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /time_records/1
    # DELETE /time_records/1.json
    def destroy
      @time_record = TimeRecord.find(params[:id])
      @time_record.destroy

      respond_to do |format|
        format.html { redirect_to time_records_url,
                      notice: (crud_notice('destroyed', @time_record) + "#{undo_link(@time_record)}").html_safe }
        format.json { head :no_content }
      end
    end

    private

    # Keeps filter state
    def manage_filter_state
      # worker
      if params[:Worker]
        session[:Worker] = params[:Worker]
      elsif session[:Worker]
        params[:Worker] = session[:Worker]
      end
      # from
      if params[:From]
        session[:From] = params[:From]
      elsif session[:From]
        params[:From] = session[:From]
      end
      # to
      if params[:To]
        session[:To] = params[:To]
      elsif session[:To]
        params[:To] = session[:To]
      end
      # type
      if params[:Type]
        session[:Type] = params[:Type]
      elsif session[:Type]
        params[:Type] = session[:Type]
      end
      # code
      if params[:Code]
        session[:Code] = params[:Code]
      elsif session[:Code]
        params[:Code] = session[:Code]
      end
    end
  end
end
