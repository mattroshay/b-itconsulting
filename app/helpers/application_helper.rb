module ApplicationHelper
  # pick the best cover: first image if present, else first media
  def article_cover(article)
    article.media_images.first || article.media.first
  end

  def attachment_image?(attachment)
    attachment.blob&.content_type.to_s.start_with?("image/")
  end

  # render the cover consistently (no controls on index)
  def article_cover_tag(attachment, alt:)
    return content_tag(:div, "", class: "media-placeholder") unless attachment

    if attachment_image?(attachment)
      image_tag url_for(attachment), alt: alt, loading: "lazy", decoding: "async"
    else
      # video: show a quiet teaser; controls on the show page only
      video_tag url_for(attachment),
                muted: true, playsinline: true, preload: "metadata",
                class: "video"
    end
  end
end
