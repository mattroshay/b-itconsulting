class ContactMailer < ApplicationMailer
  default to: 'roshaym@gmail.com'

  def contact_email(form)
    @form = form
    mail(from: @form.email, subject: @form.subject.presence || "Nouvelle demande de contact")
  end
end
