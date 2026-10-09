module ImagesHelper
  # Pass a single attachment (or one member of Activity#images).
  def attachment_image_tag(attachment, **options)
    attached = attachment.present? && (attachment.is_a?(ActiveStorage::Attachment) || attachment.attached?)
    image = attached && (attachment.is_a?(ActiveStorage::Attachment) ? attachment : attachment.attachment)
    source = image ? protected_image_path(image) : "image_placeholder.svg"
    image_tag(source, **options)
  end
end
