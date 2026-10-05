require "rails_helper"

RSpec.describe SubscriptionOshi, type: :model do
  it "belongs to its subscription and oshi without automatic deletion" do
    record = create(:subscription_oshi)
    expect(record.subscription.subscription_oshis).to contain_exactly(record)
    expect(record.oshi.subscription_oshis).to contain_exactly(record)
    [ :subscription, :oshi ].each do |name|
      association = described_class.reflect_on_association(name)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options).not_to have_key(:dependent)
    end
  end

  [ :subscription, :oshi ].each do |association|
    it "requires #{association}" do
      expect(build(:subscription_oshi, association => nil)).not_to be_valid
    end
  end

  it "rejects a duplicate subscription and oshi pair" do
    original = create(:subscription_oshi)
    record = build(:subscription_oshi, subscription: original.subscription, oshi: original.oshi)
    expect(record).not_to be_valid
    expect(record.errors[:oshi_id]).not_to be_empty
  end

  it "allows another subscription for the same oshi" do
    original = create(:subscription_oshi)
    expect(create(:subscription_oshi, oshi: original.oshi)).to be_persisted
  end

  it "allows another oshi for the same subscription" do
    original = create(:subscription_oshi)
    expect(create(:subscription_oshi, subscription: original.subscription)).to be_persisted
  end

  describe "database structure and constraints" do
    it "has only the specified columns, with no amount" do
      expected = {
        "id" => [ :integer, 8 ],
        "subscription_id" => [ :integer, 8 ],
        "oshi_id" => [ :integer, 8 ],
        "created_at" => [ :datetime, nil ],
        "updated_at" => [ :datetime, nil ]
      }
      expect(described_class.column_names).to match_array(expected.keys)
      expected.each do |name, definition|
        column = described_class.columns_hash.fetch(name)
        expect([ column.type, column.limit ]).to eq(definition)
        expect(column.null).to be(false)
        unless name == "id"
          expect(column.default).to be_nil
          expect(column.default_function).to be_nil
        end
      end
      [ "created_at", "updated_at" ].each do |name|
        expect(described_class.columns_hash.fetch(name).precision).to eq(6)
      end
    end

    [ :subscription_id, :oshi_id ].each do |attribute|
      it "rejects NULL #{attribute} without model validation" do
        record = build(:subscription_oshi, subscription: create(:subscription), oshi: create(:oshi))
        record.public_send("#{attribute}=", nil)
        expect do
          described_class.transaction(requires_new: true) { record.save!(validate: false) }
        end.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    { subscription: Subscription, oshi: Oshi }.each do |association, model|
      it "enforces the #{association} foreign key" do
        record = build(:subscription_oshi, subscription: create(:subscription), oshi: create(:oshi))
        record.public_send("#{association}=", nil)
        record.public_send("#{association}_id=", model.maximum(:id).to_i + 1)
        expect do
          described_class.transaction(requires_new: true) { record.save!(validate: false) }
        end.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    it "has both nonunique indexes and the composite unique index" do
      indexes = described_class.connection.indexes("subscription_oshis")
      expect(indexes.map { |index| [ index.columns, index.unique ] }).to contain_exactly(
        [ [ "subscription_id" ], false ],
        [ [ "oshi_id" ], false ],
        [ [ "subscription_id", "oshi_id" ], true ]
      )
    end

    it "rejects a duplicate pair without model validation" do
      duplicate = create(:subscription_oshi).dup
      expect do
        described_class.transaction(requires_new: true) { duplicate.save!(validate: false) }
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
