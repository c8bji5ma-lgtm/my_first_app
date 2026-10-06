require "stringio"

module ImageAttachments
  def image_upload(filename = "image.png", size: nil)
    data = File.binread(Rails.root.join("spec/fixtures/files", filename))
    data = data.ljust(size, "\0") if size
    { io: StringIO.new(data), filename: filename }
  end
end
