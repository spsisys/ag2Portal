module Ag2Directory
  class ApplicationController < ::ApplicationController
    mattr_accessor :reset_session_variables_for_filters

    layout 'layouts/application'

    def reset_session_variables_for_filters
      session[:search] = nil
      session[:letter] = nil
      session[:ContactType] = nil
      session[:sort] = nil
      session[:direction] = nil
    end
  end
end
