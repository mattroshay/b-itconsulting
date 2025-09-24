class ContactMailer < ApplicationMailer
  default to: 'benoit.marfany@b-itconsulting.com'

  def contact_email(form)
    @form = form
    mail(
      subject: @form.subject.presence || "Nouvelle demande de contact",
      reply_to: @form.email
    )
  end
end
