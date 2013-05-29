require_dependency "ag2_admin/application_controller"

module Ag2Admin
  class ProvincesController < ApplicationController
    before_filter :authenticate_user!
    load_and_authorize_resource
    # GET /provinces
    # GET /provinces.json
    def index
      @provinces = Province.paginate(:page => params[:page], :per_page => per_page).order('name')

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @provinces }
      end
    end

    # GET /provinces/1
    # GET /provinces/1.json
    def show
      @breadcrumb = 'read'
      @province = Province.find(params[:id])
      @towns = @province.towns.order("name")

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @province }
      end
    end

    # GET /provinces/new
    # GET /provinces/new.json
    def new
      @breadcrumb = 'create'
      @province = Province.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @province }
      end
    end

    # GET /provinces/1/edit
    def edit
      @breadcrumb = 'update'
      @province = Province.find(params[:id])
    end

    # POST /provinces
    # POST /provinces.json
    def create
      @breadcrumb = 'create'
      @province = Province.new(params[:province])
      @province.created_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @province.save
          format.html { redirect_to @province, notice: crud_notice('created', @province) }
          format.json { render json: @province, status: :created, location: @province }
        else
          format.html { render action: "new" }
          format.json { render json: @province.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /provinces/1
    # PUT /provinces/1.json
    def update
      @breadcrumb = 'update'
      @province = Province.find(params[:id])
      @province.updated_by = current_user.id if !current_user.nil?

      respond_to do |format|
        if @province.update_attributes(params[:province])
          format.html { redirect_to @province,
                        notice: (crud_notice('updated', @province) + "#{undo_link(@province)}").html_safe }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @province.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /provinces/1
    # DELETE /provinces/1.json
    def destroy
      @province = Province.find(params[:id])
      @province.destroy

      respond_to do |format|
        format.html { redirect_to provinces_url,
                      notice: (crud_notice('destroyed', @province) + "#{undo_link(@province)}").html_safe }
        format.json { head :no_content }
      end
    end
  end
end
