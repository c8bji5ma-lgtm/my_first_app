require "rails_helper"

RSpec.describe UserOshi, type: :model do
  it "belongs to its user and oshi" do
    record = create(:user_oshi)
    expect(record.user.user_oshis).to contain_exactly(record)
    expect(record.oshi.user_oshis).to contain_exactly(record)
    expect(record.user.oshis).to contain_exactly(record.oshi)
  end

  [ :user, :oshi ].each do |association|
    it "requires #{association}" do
      expect(build(:user_oshi, association => nil)).not_to be_valid
    end
  end

  it "rejects a duplicate pair even after ending" do
    original = create(:user_oshi, ended_period: "2024")
    expect(build(:user_oshi, user: original.user, oshi: original.oshi)).not_to be_valid
  end

  it "allows another user for the same oshi" do
    original = create(:user_oshi)
    expect(create(:user_oshi, oshi: original.oshi)).to be_persisted
  end

  it "allows another oshi for the same user" do
    original = create(:user_oshi)
    expect(create(:user_oshi, user: original.user)).to be_persisted
  end

  [ :started_period, :ended_period ].each do |attribute|
    [ nil, "2023", "2023/01", "2023/05", "2023/12" ].each do |value|
      it "accepts and preserves #{attribute}=#{value.inspect}" do
        record = create(:user_oshi, attribute => value)
        expect(record.reload.public_send(attribute)).to eq(value)
      end
    end

    it "normalizes only an empty string in #{attribute} to nil" do
      record = create(:user_oshi, attribute => "")
      expect(record.reload.public_send(attribute)).to be_nil
    end

    [ "2023/5", "2023/00", "2023/13", "2023-05", "2023/05/01",
      " ", "   ", " 2023", "2023 ", " 2023 ", "2023/05 ",
      "2023/05\n", "2023\n", "202\n3", "２０２３" ].each do |value|
      it "rejects #{attribute}=#{value.inspect}" do
        expect(build(:user_oshi, attribute => value)).not_to be_valid
      end
    end
  end

  it "reuses the original record when clearing ended_period" do
    record = create(:user_oshi, started_period: "2023", ended_period: "2024/05")
    original_id = record.id
    expect { record.update!(ended_period: nil) }.not_to change(described_class, :count)
    record.reload
    expect(record.id).to eq(original_id)
    expect(record.started_period).to eq("2023")
    expect(record.ended_period).to be_nil
  end

  describe "database constraints" do
    it "rejects NULL user_id at the database" do
      record = build(:user_oshi)
      record.user = create(:user)
      record.oshi = create(:oshi)
      record.user_id = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL oshi_id at the database" do
      record = build(:user_oshi)
      record.user = create(:user)
      record.oshi = create(:oshi)
      record.oshi_id = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
    it "enforces the user_id foreign key" do
      record = build(:user_oshi)
      record.oshi = create(:oshi)
      record.user = nil
      record.user_id = User.maximum(:id).to_i + 1
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "enforces the oshi_id foreign key" do
      record = build(:user_oshi)
      record.user = create(:user)
      record.oshi = nil
      record.oshi_id = Oshi.maximum(:id).to_i + 1
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end
    it "has a nonunique index on user_id" do
      indexes = described_class.connection.indexes("user_oshis")
      expect(indexes.any? { |index| index.columns == [ "user_id" ] && index.unique == false }).to be(true)
    end

    it "has a nonunique index on oshi_id" do
      indexes = described_class.connection.indexes("user_oshis")
      expect(indexes.any? { |index| index.columns == [ "oshi_id" ] && index.unique == false }).to be(true)
    end

    it "has a unique index on user_id, oshi_id" do
      indexes = described_class.connection.indexes("user_oshis")
      expect(indexes.any? { |index| index.columns == [ "user_id", "oshi_id" ] && index.unique == true }).to be(true)
    end
    it "enforces database uniqueness without model validation" do
      original = create(:user_oshi)
      duplicate = original.dup
      expect do
        described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
