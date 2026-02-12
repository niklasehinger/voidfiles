class SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  rescue Warden::AuthenticationError => e
    # Check if user was not found in database
    if e.message.include?("not found") || e.message.include?("invalid")
      set_flash.now[:alert] = "Diese E-Mail-Adresse ist nicht registriert. Bitte erstelle zuerst ein Konto."
    else
      set_flash.now[:alert] = "E-Mail-Adresse oder Passwort ist falsch."
    end
    render :new, status: :unprocessable_entity
  end
end
