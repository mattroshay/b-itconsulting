class ContactForm
  include ActiveModel::Model

  attr_accessor :first_name, :last_name, :email, :subject, :message

  validates :first_name, :last_name, :email, :subject, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
