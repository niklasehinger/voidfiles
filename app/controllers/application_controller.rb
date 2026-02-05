class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :redirect_to_dashboard_if_authenticated
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    dashboard_path(locale: I18n.locale)
  end

  def after_sign_up_path_for(resource)
    dashboard_path(locale: I18n.locale)
  end

  private

  def set_locale
    if params[:locale].present?
      session[:locale] = params[:locale]
    end
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def redirect_to_dashboard_if_authenticated
    # Only redirect for GET requests to root path (with or without locale)
    if user_signed_in? && request.get? && [root_path, "/"].include?(request.path)
      redirect_to dashboard_path(locale: I18n.locale)
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
