# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :user

  has_many_attached :media

  validates :title, :content, presence: true
  validate  :media_types_ok

  def media_images
    media.select { |m| m.content_type&.start_with?("image/") }
  end

  def media_videos
    media.select { |m| m.content_type&.start_with?("video/") }
  end

  private

  def media_types_ok
    media.each do |file|
      ct = file.content_type.to_s
      unless ct.start_with?("image/") || ct.start_with?("video/")
        errors.add(:media, "must be an image or a video (got #{ct.presence || 'unknown'})")
      end
    end
  end
end
