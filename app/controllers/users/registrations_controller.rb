class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :avatar])
  end

  def update_resource(resource, params)
    # Allow users to update without password if only changing profile info
    if params[:password].blank?
      resource.update_without_password(params.except(:current_password, :password, :password_confirmation))
    else
      # Changing password - require current password
      resource.update_with_password(params)
    end
  end
end
