require_dependency "ag2_gest/application_controller"

module Ag2Gest
  class ReadingTypesController < ApplicationController
    # GET /reading_types
    # GET /reading_types.json
    def index
      @reading_types = ReadingType.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @reading_types }
      end
    end
  
    # GET /reading_types/1
    # GET /reading_types/1.json
    def show
      @reading_type = ReadingType.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @reading_type }
      end
    end
  
    # GET /reading_types/new
    # GET /reading_types/new.json
    def new
      @reading_type = ReadingType.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @reading_type }
      end
    end
  
    # GET /reading_types/1/edit
    def edit
      @reading_type = ReadingType.find(params[:id])
    end
  
    # POST /reading_types
    # POST /reading_types.json
    def create
      @reading_type = ReadingType.new(params[:reading_type])
  
      respond_to do |format|
        if @reading_type.save
          format.html { redirect_to @reading_type, notice: 'Reading type was successfully created.' }
          format.json { render json: @reading_type, status: :created, location: @reading_type }
        else
          format.html { render action: "new" }
          format.json { render json: @reading_type.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /reading_types/1
    # PUT /reading_types/1.json
    def update
      @reading_type = ReadingType.find(params[:id])
  
      respond_to do |format|
        if @reading_type.update_attributes(params[:reading_type])
          format.html { redirect_to @reading_type, notice: 'Reading type was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @reading_type.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /reading_types/1
    # DELETE /reading_types/1.json
    def destroy
      @reading_type = ReadingType.find(params[:id])
      @reading_type.destroy
  
      respond_to do |format|
        format.html { redirect_to reading_types_url }
        format.json { head :no_content }
      end
    end
  end
end