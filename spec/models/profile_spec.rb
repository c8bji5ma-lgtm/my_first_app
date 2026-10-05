require "rails_helper"

RSpec.describe Profile, type: :model do
  it "belongs to its user and is accessible from that user" do
    profile = create(:profile)
    expect(profile.user.reload.profile).to eq(profile)
  end

  it "requires a user" do
    expect(build(:profile, user: nil)).not_to be_valid
  end

  it "allows optional introduction" do
    expect(build(:profile, introduction: nil)).to be_valid
  end

  it "rejects a second profile for the same user" do
    profile = create(:profile)
    expect(build(:profile, user: profile.user)).not_to be_valid
  end

  it "accepts 50 characters for display_name" do
    expect(build(:profile, display_name: "あ" * 50)).to be_valid
  end

  it "rejects more than 50 characters for display_name" do
    expect(build(:profile, display_name: "あ" * 51)).not_to be_valid
  end

  it "requires display_name" do
    [ nil, "", " " ].each do |value|
      expect(build(:profile, display_name: value)).not_to be_valid
    end
  end

  describe "database constraints" do
    it "rejects NULL user_id at the database" do
      record = build(:profile)
      record.user = create(:user)
      record.user_id = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL display_name at the database" do
      record = build(:profile)
      record.user = create(:user)
      record.display_name = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
    it "enforces the user_id foreign key" do
      record = build(:profile)

      record.user = nil
      record.user_id = User.maximum(:id).to_i + 1
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end
    it "has a unique index on user_id" do
      indexes = described_class.connection.indexes("profiles")
      expect(indexes.any? { |index| index.columns == [ "user_id" ] && index.unique == true }).to be(true)
    end
    it "enforces database uniqueness without model validation" do
      original = create(:profile)
      duplicate = original.dup
      expect do
        described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
