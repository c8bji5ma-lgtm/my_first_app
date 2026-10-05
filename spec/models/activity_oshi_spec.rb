require "rails_helper"

RSpec.describe ActivityOshi, type: :model do
  it "belongs to an activity and oshi without automatic deletion" do
    record = create(:activity_oshi)
    expect(record.activity.activity_oshis).to include(record)
    expect(record.oshi.activity_oshis).to contain_exactly(record)
    [ :activity, :oshi ].each do |name|
      association = described_class.reflect_on_association(name)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options).not_to have_key(:dependent)
    end
  end

  [ :activity, :oshi ].each do |association|
    it "requires #{association}" do
      expect(build(:activity_oshi, association => nil)).not_to be_valid
    end
  end

  it "rejects the same activity and oshi pair" do
    original = create(:activity_oshi)
    expect(build(:activity_oshi, activity: original.activity, oshi: original.oshi)).not_to be_valid
  end

  it "allows the same oshi in a different activity" do
    original = create(:activity_oshi)
    expect(create(:activity_oshi, oshi: original.oshi)).to be_persisted
  end

  it "allows another oshi in the same activity" do
    original = create(:activity_oshi)
    expect(create(:activity_oshi, activity: original.activity)).to be_persisted
  end

  it "refuses to destroy the last link" do
    activity = create(:activity)
    record = activity.activity_oshis.first
    expect(record.destroy).to be(false)
    expect(record.errors[:base]).to include("Activity must retain at least one oshi")
    expect(activity.reload.activity_oshis.count).to eq(1)
    expect { record.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  end

  it "destroys one of two links and protects the remaining link" do
    activity = create(:activity, :multiple_oshis)
    activity.activity_oshis.first.destroy!
    expect(activity.reload.activity_oshis.count).to eq(1)
    expect(activity.activity_oshis.first.destroy).to be(false)
  end

  it "checks database links even if the parent association was already loaded" do
    activity = create(:activity, :multiple_oshis)
    activity.activity_oshis.load
    first, second = activity.activity_oshis.to_a
    first.destroy!
    expect(second.destroy).to be(false)
    expect(activity.reload.activity_oshis.count).to eq(1)
  end

  describe "database constraints" do
    [ :activity_id, :oshi_id ].each do |attribute|
      it "rejects NULL #{attribute} without validation" do
        record = create(:activity_oshi)
        expect do
          described_class.transaction(requires_new: true) { record.update_columns(attribute => nil) }
        end.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    { activity_id: Activity, oshi_id: Oshi }.each do |attribute, model|
      it "enforces the #{attribute} foreign key" do
        record = create(:activity_oshi)
        expect do
          described_class.transaction(requires_new: true) do
            record.update_columns(attribute => model.maximum(:id).to_i + 1)
          end
        end.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    it "enforces pair uniqueness without validation" do
      duplicate = create(:activity_oshi).dup
      expect do
        described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "has two individual indexes and the composite unique index" do
      indexes = described_class.connection.indexes("activity_oshis")
      expect(indexes.map { |index| [ index.columns, index.unique ] }).to match_array([
        [ [ "activity_id" ], false ], [ [ "oshi_id" ], false ],
        [ [ "activity_id", "oshi_id" ], true ]
      ])
    end

    it "has no nullable columns or amount column" do
      expect(described_class.columns).to all(have_attributes(null: false))
      expect(described_class.column_names).not_to include("amount")
    end
  end
end
