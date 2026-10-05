require "rails_helper"

RSpec.describe User, type: :model do
  it "has activities without automatic deletion" do
    association = described_class.reflect_on_association(:activities)
    expect(association.macro).to eq(:has_many)
    expect(association.options).not_to have_key(:dependent)
    user = create(:user)
    activity = create(:activity, user: user)
    expect(user.activities).to contain_exactly(activity)
  end

  it "defines the Issue #17 associations without automatic deletion" do
    {
      profile: :has_one,
      user_oshis: :has_many,
      oshis: :has_many,
      created_oshis: :has_many
    }.each do |name, macro|
      association = described_class.reflect_on_association(name)
      expect(association.macro).to eq(macro)
      expect(association.options).not_to have_key(:dependent)
    end

    expect(described_class.reflect_on_association(:oshis).options[:through]).to eq(:user_oshis)
    creator_association = described_class.reflect_on_association(:created_oshis)
    expect(creator_association.class_name).to eq("Oshi")
    expect(creator_association.foreign_key).to eq("created_by_user_id")
  end

  it "accepts valid registration attributes" do
    expect(build(:user)).to be_valid
  end

  it "requires an email" do
    expect(build(:user, email: nil)).not_to be_valid
  end

  it "rejects invalid email formats" do
    expect(build(:user, email: "invalid")).not_to be_valid
  end

  it "rejects duplicate emails regardless of case" do
    user = create(:user)
    expect(build(:user, email: user.email.upcase)).not_to be_valid
  end

  it "requires a password on registration" do
    expect(build(:user, password: nil, password_confirmation: nil)).not_to be_valid
  end

  it "rejects passwords shorter than the configured minimum" do
    expect(build(:user, password: "a" * (Devise.password_length.min - 1))).not_to be_valid
  end

  it "rejects passwords longer than the configured maximum" do
    expect(build(:user, password: "a" * (Devise.password_length.max + 1))).not_to be_valid
  end

  it "rejects a mismatched password confirmation" do
    expect(build(:user, password_confirmation: "different")).not_to be_valid
  end

  it "stores an encrypted password instead of plaintext" do
    user = create(:user)
    expect(user.encrypted_password).not_to eq(user.password)
    expect(user.valid_password?("password123")).to be(true)
  end

  it "defaults to a non-admin user" do
    user = create(:user)
    expect(user.reload.admin).to be(false)
    expect(user.admin?).to be(false)
  end

  it "identifies an admin" do
    expect(create(:user, :admin).admin?).to be(true)
  end

  it "rejects a missing admin flag" do
    expect(build(:user, admin: nil)).not_to be_valid
  end
end
