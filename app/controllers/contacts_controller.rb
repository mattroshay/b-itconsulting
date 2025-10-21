class ContactsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  def new
    @form = ContactForm.new
  end

  def create
    @form = ContactForm.new(contact_form_params)

    if @form.valid?
      begin
        ContactMailer.contact_email(@form).deliver_now
        ContactMailer.confirmation_email(@form).deliver_now
        redirect_to contact_path, notice: "Votre message a été envoyé avec succès."
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        Rails.logger.error "SMTP Error sending contact form: #{e.class} - #{e.message}"
        flash.now[:alert] = "Erreur lors de l'envoi du message. Veuillez réessayer plus tard."
        render :new, status: :unprocessable_entity
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
        Rails.logger.error "SMTP Connection Error: #{e.class} - #{e.message}\nSMTP Settings: #{Rails.configuration.action_mailer.smtp_settings.except(:password).inspect}"
        flash.now[:alert] = "Impossible de se connecter au serveur d'email. Veuillez réessayer plus tard."
        render :new, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error "Unexpected error sending contact email: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\\n")}"
        flash.now[:alert] = "Une erreur inattendue s'est produite. Veuillez réessayer."
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_form_params
    params.require(:contact_form).permit(:first_name, :last_name, :email, :subject, :message)
  end
end
