module ImagesHelper
  # Pass a single attachment (or one member of Activity#images).
  def attachment_image_tag(attachment, **options)
    source = attachment.present? && (attachment.is_a?(ActiveStorage::Attachment) || attachment.attached?) ? attachment : "image_placeholder.svg"
    image_tag(source, **options)
  end
end
