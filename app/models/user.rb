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
    name = "#{first_name.to_s}+#{last_name.to_s}"
    "https://ui-avatars.com/api/?name=#{ERB::Util.url_encode(name)}&background=0D6EFD&color=fff"
  end
end
