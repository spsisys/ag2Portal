class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  # before_filter :set_charset
  before_filter :set_locale

  layout :layout
  helper_method :letters

  def letters
    @letters = ('A'..'Z')
  end

  def set_locale
    # I18n.locale = params[:locale] || I18n.default_locale
    I18n.locale = params[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def self.default_url_options
    { :locale => I18n.locale }
  end
  
=begin
  def default_url_options(options={})
    # logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { :locale => I18n.locale }
  end

  def set_charset
    # @headers["Content-Type"] = "text/html; charset=utf-8"
  end
=end

  private

  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

  def layout
    # turn layout off for session and registration pages
    # and on for the others
    if is_a?(Devise::SessionsController)
      "session"
    elsif is_a?(Devise::RegistrationsController)
      if user_signed_in?
        "profile"
      else
        "registration"
      end
    else
      "application"
    end

  # turn it off for registration pages:
  # is_a?(Devise::SessionsController) ? "session" : "application"
  # turn it off for registration pages:
  # is_a?(Devise::RegistrationsController) ? "registration" : "application"
  # or turn layout off for every devise controller:
  # devise_controller? && "application"

  # turn it off for welcome page: Controller
  end
end
