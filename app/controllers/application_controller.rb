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
    # Skip redirect - allow authenticated users to access all pages including index
    # The dashboard is the default after sign-in, but users can navigate to index manually
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :avatar ])
  end
end
