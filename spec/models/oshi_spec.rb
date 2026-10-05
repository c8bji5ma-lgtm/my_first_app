require "rails_helper"

RSpec.describe Oshi, type: :model do
  it "exposes subscription_oshis and subscriptions without automatic deletion" do
    record = create(:subscription_oshi)
    expect(record.oshi.subscription_oshis).to contain_exactly(record)
    expect(record.oshi.subscriptions).to contain_exactly(record.subscription)
    [ :subscription_oshis, :subscriptions ].each do |name|
      association = described_class.reflect_on_association(name)
      expect(association.macro).to eq(:has_many)
      expect(association.options).not_to have_key(:dependent)
    end
    expect(described_class.reflect_on_association(:subscriptions).options[:through]).to eq(:subscription_oshis)
  end

  it "belongs to its creator and is accessible from that user" do
    creator = create(:user)
    oshi = create(:oshi, created_by_user: creator)
    expect(oshi.reload.created_by_user).to eq(creator)
    expect(creator.created_oshis).to contain_exactly(oshi)
  end

  it "allows no creator" do
    expect(build(:oshi, created_by_user: nil)).to be_valid
  end

  it "exposes aliases, user_oshis, and users through user_oshis" do
    oshi = create(:oshi)
    alias_record = create(:oshi_alias, oshi: oshi)
    user_oshi = create(:user_oshi, oshi: oshi)
    expect(oshi.oshi_aliases).to contain_exactly(alias_record)
    expect(oshi.user_oshis).to contain_exactly(user_oshi)
    expect(oshi.users).to contain_exactly(user_oshi.user)
  end

  it "allows duplicate names" do
    original = create(:oshi)
    expect(create(:oshi, name: original.name)).to be_persisted
  end

  it "allows all seven specified oshi types" do
    [ "アイドル", "アーティスト", "俳優・タレント", "声優",
      "キャラクター", "スポーツ", "その他" ].each do |value|
      expect(build(:oshi, oshi_type: value)).to be_valid
    end
  end

  it "rejects missing or unknown oshi types" do
    [ nil, "", "unknown" ].each do |value|
      expect(build(:oshi, oshi_type: value)).not_to be_valid
    end
  end

  it "defaults to pending and persists that value" do
    expect(build(:oshi).status).to eq("pending")
    expect(create(:oshi).reload.status).to eq("pending")
    expect(described_class.columns_hash.fetch("status").default).to eq("pending")
  end

  [ "pending", "approved", "rejected" ].each do |status|
    it "persists the #{status} status as a string" do
      oshi = create(:oshi, status.to_sym)
      expect(oshi.reload.status).to eq(status)
      expect(oshi.status_before_type_cast).to eq(status)
    end
  end

  it "rejects unknown and nil statuses" do
    [ "unknown", nil ].each do |value|
      expect(build(:oshi, status: value)).not_to be_valid
    end
  end

  it "accepts 255 characters for name" do
    expect(build(:oshi, name: "あ" * 255)).to be_valid
  end

  it "rejects more than 255 characters for name" do
    expect(build(:oshi, name: "あ" * 256)).not_to be_valid
  end

  it "requires name" do
    [ nil, "", " " ].each do |value|
      expect(build(:oshi, name: value)).not_to be_valid
    end
  end

  it "accepts 255 characters for affiliation" do
    expect(build(:oshi, affiliation: "あ" * 255)).to be_valid
  end

  it "rejects more than 255 characters for affiliation" do
    expect(build(:oshi, affiliation: "あ" * 256)).not_to be_valid
  end

  describe "database constraints" do
    it "rejects NULL name at the database" do
      record = build(:oshi)
      record.created_by_user = create(:user)
      record.name = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL oshi_type at the database" do
      record = build(:oshi)
      record.created_by_user = create(:user)
      record.oshi_type = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL status at the database" do
      record = build(:oshi)
      record.created_by_user = create(:user)
      record.status = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
    it "enforces the created_by_user_id foreign key" do
      record = build(:oshi)

      record.created_by_user = nil
      record.created_by_user_id = User.maximum(:id).to_i + 1
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end
    it "has a nonunique index on name" do
      indexes = described_class.connection.indexes("oshis")
      expect(indexes.any? { |index| index.columns == [ "name" ] && index.unique == false }).to be(true)
    end

    it "has a nonunique index on created_by_user_id" do
      indexes = described_class.connection.indexes("oshis")
      expect(indexes.any? { |index| index.columns == [ "created_by_user_id" ] && index.unique == false }).to be(true)
    end
  end
end
