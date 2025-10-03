class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def avatar_url
    name = "#{first_name}+#{last_name}"
    "https://ui-avatars.com/api/?name=#{CGI.escape(name)}&background=0D6EFD&color=fff"
  end
end
