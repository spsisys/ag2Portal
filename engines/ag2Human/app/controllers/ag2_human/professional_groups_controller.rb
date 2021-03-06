require_dependency "ag2_human/application_controller"

module Ag2Human
  class ProfessionalGroupsController < ApplicationController
    before_filter :authenticate_user!
    load_and_authorize_resource
    # Helper methods for sorting
    helper_method :sort_column
    # GET /professional_groups
    # GET /professional_groups.json
    def index
      init_oco if !session[:organization]
      if session[:organization] != '0'
        @professional_groups = ProfessionalGroup.where(organization_id: session[:organization]).paginate(:page => params[:page], :per_page => per_page).order(sort_column + ' ' + sort_direction)
      else
        @professional_groups = ProfessionalGroup.paginate(:page => params[:page], :per_page => per_page).order(sort_column + ' ' + sort_direction)
      end

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @professional_groups }
      end
    end

    # GET /professional_groups/1
    # GET /professional_groups/1.json
    def show
      @breadcrumb = 'read'
      @professional_group = ProfessionalGroup.find(params[:id])
      @workers = @professional_group.workers.paginate(:page => params[:page], :per_page => per_page).order('worker_code')

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @professional_group }
      end
    end

    # GET /professional_groups/new
    # GET /professional_groups/new.json
    def new
      @breadcrumb = 'create'
      @professional_group = ProfessionalGroup.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @professional_group }
      end
    end

    # GET /professional_groups/1/edit
    def edit
      @breadcrumb = 'update'
      @professional_group = ProfessionalGroup.find(params[:id])
    end

    # POST /professional_groups
    # POST /professional_groups.json
    def create
      @breadcrumb = 'create'
      @professional_group = ProfessionalGroup.new(params[:professional_group])
      @professional_group.created_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @professional_group.save
          format.html { redirect_to @professional_group, notice: crud_notice('created', @professional_group) }
          format.json { render json: @professional_group, status: :created, location: @professional_group }
        else
          format.html { render action: "new" }
          format.json { render json: @professional_group.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /professional_groups/1
    # PUT /professional_groups/1.json
    def update
      @breadcrumb = 'update'
      @professional_group = ProfessionalGroup.find(params[:id])
      @professional_group.updated_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @professional_group.update_attributes(params[:professional_group])
          format.html { redirect_to @professional_group,
                        notice: (crud_notice('updated', @professional_group) + "#{undo_link(@professional_group)}").html_safe }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @professional_group.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /professional_groups/1
    # DELETE /professional_groups/1.json
    def destroy
      @professional_group = ProfessionalGroup.find(params[:id])

      respond_to do |format|
        if @professional_group.destroy
          format.html { redirect_to professional_groups_url,
                      notice: (crud_notice('destroyed', @professional_group) + "#{undo_link(@professional_group)}").html_safe }
          format.json { head :no_content }
        else
          format.html { redirect_to professional_groups_url, alert: "#{@professional_group.errors[:base].to_s}".gsub('["', '').gsub('"]', '') }
          format.json { render json: @professional_group.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def sort_column
      ProfessionalGroup.column_names.include?(params[:sort]) ? params[:sort] : "pg_code"
    end
  end
end
