class ImageAttachmentValidator < ActiveModel::EachValidator
  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_BYTE_SIZE = 10 * 1024 * 1024

  def validate_each(record, attribute, value)
    return unless value.attached?

    attachments = value.is_a?(ActiveStorage::Attached::Many) ? value.attachments : [ value.attachment ]
    attachments.each do |attachment|
      blob = attachment.blob
      unless CONTENT_TYPES.include?(blob.content_type)
        record.errors.add(attribute, "はJPEG・PNG・WebP形式の画像を指定してください")
      end
      if blob.byte_size > MAX_BYTE_SIZE
        record.errors.add(attribute, "は1画像あたり10 MiB以下にしてください")
      end
    end
  end
end
