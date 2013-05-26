require_dependency "ag2_help_desk/application_controller"

module Ag2HelpDesk
  class TicketCategoriesController < ApplicationController
    before_filter :authenticate_user!
    load_and_authorize_resource

    # GET /ticket_categories
    # GET /ticket_categories.json
    def index
      @ticket_categories = TicketCategory.paginate(:page => params[:page], :per_page => per_page).order('name')
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @ticket_categories }
      end
    end
  
    # GET /ticket_categories/1
    # GET /ticket_categories/1.json
    def show
      @breadcrumb = 'read'
      @ticket_category = TicketCategory.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @ticket_category }
      end
    end
  
    # GET /ticket_categories/new
    # GET /ticket_categories/new.json
    def new
      @breadcrumb = 'create'
      @ticket_category = TicketCategory.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @ticket_category }
      end
    end
  
    # GET /ticket_categories/1/edit
    def edit
      @breadcrumb = 'update'
      @ticket_category = TicketCategory.find(params[:id])
    end
  
    # POST /ticket_categories
    # POST /ticket_categories.json
    def create
      @breadcrumb = 'create'
      @ticket_category = TicketCategory.new(params[:ticket_category])
      @ticket_category.created_by = current_user.id if !current_user.nil?
  
      respond_to do |format|
        if @ticket_category.save
          format.html { redirect_to @ticket_category, notice: I18n.t('activerecord.successful.messages.created', :model => @ticket_category.class.model_name.human) }
          format.json { render json: @ticket_category, status: :created, location: @ticket_category }
        else
          format.html { render action: "new" }
          format.json { render json: @ticket_category.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /ticket_categories/1
    # PUT /ticket_categories/1.json
    def update
      @breadcrumb = 'update'
      @ticket_category = TicketCategory.find(params[:id])
      @ticket_category.updated_by = current_user.id if !current_user.nil?
  
      respond_to do |format|
        if @ticket_category.update_attributes(params[:ticket_category])
          format.html { redirect_to @ticket_category, notice: I18n.t('activerecord.successful.messages.updated', :model => @ticket_category.class.model_name.human) }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @ticket_category.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /ticket_categories/1
    # DELETE /ticket_categories/1.json
    def destroy
      @ticket_category = TicketCategory.find(params[:id])
      @ticket_category.destroy
  
      respond_to do |format|
        format.html { redirect_to ticket_categories_url }
        format.json { head :no_content }
      end
    end
  end
end