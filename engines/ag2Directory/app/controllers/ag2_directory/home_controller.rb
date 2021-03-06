require_dependency "ag2_directory/application_controller"

module Ag2Directory
  class HomeController < ApplicationController
    def index
      @ag2teamnet_path, @ag2teamnet_target = website_path('ag2TeamNet', '_self')
      reset_session_variables_for_filters
    end
  end
end
