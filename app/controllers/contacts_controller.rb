class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  def new
    @form = ContactForm.new
  end

  def create
    @form = ContactForm.new(contact_form_params)

    if @form.valid?
      ContactMailer.contact_email(@form).deliver_now
      redirect_to contact_path, notice: "Votre message a été envoyé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_form_params
    params.require(:contact_form).permit(:first_name, :last_name, :email, :subject, :message)
  end
end
