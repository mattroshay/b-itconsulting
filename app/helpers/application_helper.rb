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

  # Force Cloudinary helper to ignore the global folder Active Storage might set
  def cl_image_path(public_id, **opts)
    cdn_image_src(public_id, **{ folder: nil }.merge(opts))
  end

  def default_meta
    {
      title: "B-IT Consulting | Administration d'infrastructures sécurisées et gestion de projet IT",
      description: "Expertise en administration d'infrastructures Windows, virtualisation, cloud et gestion de projets numériques en Nouvelle-Aquitaine.",
      image: "Logo/Vista Logos/logo-transparent-png.png",
      site_name: "B-IT Consulting",
      robots: "index, follow"
    }
  end

  def meta_title
    meta_content_for(:meta_title, default_meta[:title])
  end

  def meta_description
    meta_content_for(:meta_description, default_meta[:description])
  end

  def meta_robots
    meta_content_for(:meta_robots, default_meta[:robots])
  end

  def meta_image
    image_path = meta_content_for(:meta_image, default_meta[:image])
    return if image_path.blank?

    image_path.to_s.start_with?("http", "https") ? image_path : asset_url(image_path)
  end

  def canonical_url
    fallback =
      if request&.base_url.present?
        "#{request.base_url}#{request.path}"
      elsif default_url_options[:host].present?
        "https://#{default_url_options[:host]}"
      end

    meta_content_for(:canonical_url, fallback)
  end

  def meta_site_name
    meta_content_for(:meta_site_name, default_meta[:site_name])
  end

  def set_meta_tags(title:, description:, image: nil, canonical: nil, robots: nil, site_name: nil)
    content_for(:meta_title, title) if title.present?
    content_for(:meta_description, description) if description.present?
    content_for(:meta_image, image) if image.present?
    content_for(:canonical_url, canonical) if canonical.present?
    content_for(:meta_robots, robots) if robots.present?
    content_for(:meta_site_name, site_name) if site_name.present?
  end

  private

  def meta_content_for(symbol, default = nil)
    if content_for?(symbol)
      content_for(symbol)
    else
      default
    end
  end
end
