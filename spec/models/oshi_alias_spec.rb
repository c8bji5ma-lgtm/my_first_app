require "rails_helper"

RSpec.describe OshiAlias, type: :model do
  it "belongs to its oshi" do
    record = create(:oshi_alias)
    expect(record.oshi.oshi_aliases).to contain_exactly(record)
  end

  it "requires an oshi" do
    expect(build(:oshi_alias, oshi: nil)).not_to be_valid
  end

  it "rejects the same alias within the same oshi" do
    original = create(:oshi_alias)
    expect(build(:oshi_alias, oshi: original.oshi, alias_name: original.alias_name)).not_to be_valid
  end

  it "allows the same alias for another oshi" do
    original = create(:oshi_alias)
    expect(create(:oshi_alias, alias_name: original.alias_name)).to be_persisted
  end

  it "treats letter case as distinct" do
    original = create(:oshi_alias, alias_name: "Example")
    expect(create(:oshi_alias, oshi: original.oshi, alias_name: "example")).to be_persisted
  end

  it "accepts 255 characters for alias_name" do
    expect(build(:oshi_alias, alias_name: "あ" * 255)).to be_valid
  end

  it "rejects more than 255 characters for alias_name" do
    expect(build(:oshi_alias, alias_name: "あ" * 256)).not_to be_valid
  end

  it "requires alias_name" do
    [ nil, "", " " ].each do |value|
      expect(build(:oshi_alias, alias_name: value)).not_to be_valid
    end
  end

  describe "database constraints" do
    it "rejects NULL oshi_id at the database" do
      record = build(:oshi_alias)
      record.oshi = create(:oshi)
      record.oshi_id = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL alias_name at the database" do
      record = build(:oshi_alias)
      record.oshi = create(:oshi)
      record.alias_name = nil
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
    it "enforces the oshi_id foreign key" do
      record = build(:oshi_alias)

      record.oshi = nil
      record.oshi_id = Oshi.maximum(:id).to_i + 1
      expect do
        described_class.transaction(requires_new: true) { record.save!(validate: false) }
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end
    it "has a nonunique index on oshi_id" do
      indexes = described_class.connection.indexes("oshi_aliases")
      expect(indexes.any? { |index| index.columns == [ "oshi_id" ] && index.unique == false }).to be(true)
    end

    it "has a nonunique index on alias_name" do
      indexes = described_class.connection.indexes("oshi_aliases")
      expect(indexes.any? { |index| index.columns == [ "alias_name" ] && index.unique == false }).to be(true)
    end

    it "has a unique index on oshi_id, alias_name" do
      indexes = described_class.connection.indexes("oshi_aliases")
      expect(indexes.any? { |index| index.columns == [ "oshi_id", "alias_name" ] && index.unique == true }).to be(true)
    end
    it "enforces database uniqueness without model validation" do
      original = create(:oshi_alias)
      duplicate = original.dup
      expect do
        described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
