require "rails_helper"
require_relative "../support/image_attachments"

RSpec.describe ImagesHelper, type: :helper do
  include ImageAttachments

  it "renders a placeholder for an empty attachment and accepts alt" do
    profile = build(:profile)
    html = helper.attachment_image_tag(profile.profile_image, alt: "プロフィール画像")
    expect(html).to include("image_placeholder", 'alt="プロフィール画像"')
  end

  it "renders a placeholder for nil" do
    expect(helper.attachment_image_tag(nil)).to include("image_placeholder")
  end

  it "renders the original attached image and accepts alt" do
    profile = build(:profile)
    profile.profile_image.attach(image_upload)
    profile.save!
    html = helper.attachment_image_tag(profile.profile_image, alt: "プロフィール画像")
    expect(html).to include(profile.profile_image.blob.signed_id, 'alt="プロフィール画像"')
    expect(html).not_to include("image_placeholder", "representations")
  end

  it "renders an individual Activity attachment" do
    activity = build(:activity)
    activity.images.attach(image_upload)
    activity.save!
    expect(helper.attachment_image_tag(activity.images.first)).to include(activity.images.first.blob.signed_id)
  end
end
