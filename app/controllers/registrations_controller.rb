# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?

    if resource_updated
      set_flash_message :notice, :updated
      redirect_to after_update_path_for(resource), status: :see_other
    else
      clean_up_passwords(resource)
      set_minimum_password_length
      respond_with resource, status: :unprocessable_entity
    end
  end

  private

  def after_update_path_for(resource)
    profile_path(locale: I18n.locale)
  end
end
