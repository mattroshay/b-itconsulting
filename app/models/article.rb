# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :user

  # Rich text content using Action Text
  has_rich_text :rich_content

  # Legacy images attachment (for backwards compatibility with old articles)
  has_many_attached :images

  # Additional media attachments (separate from inline Action Text attachments)
  has_many_attached :media

  validates :title, presence: true
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
      unless ct.start_with?("image/") || ct.start_with?("video/") || ct.start_with?("image/gif")
        errors.add(:media, "must be an image, video, or GIF (got #{ct.presence || 'unknown'})")
      end
    end
  end
end
