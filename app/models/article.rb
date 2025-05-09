class Article < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  #  article.photo
end
