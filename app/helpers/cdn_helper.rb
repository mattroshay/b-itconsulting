module CdnHelper
  def cdn_image_src(public_id, **opts)
    return public_id if public_id.to_s.start_with?("http://", "https://")
    Cloudinary::Utils.cloudinary_url(
      public_id,
      { resource_type: "image", type: "upload", secure: true, fetch_format: :auto, version: nil, folder: nil }.merge(opts)
    )
  end

  def cdn_image_tag(public_id_or_url, **options)
    image_tag cdn_image_src(public_id_or_url), **options
  end
end
