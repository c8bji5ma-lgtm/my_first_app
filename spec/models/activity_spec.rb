require "rails_helper"

RSpec.describe Activity, type: :model do
  it "belongs to a user and exposes its oshis through activity_oshis" do
    activity = create(:activity, :multiple_oshis)
    expect(activity.user.activities).to contain_exactly(activity)
    expect(activity.activity_oshis.size).to eq(2)
    expect(activity.oshis).to match_array(activity.activity_oshis.map(&:oshi))
  end

  it "defines the associations without automatic deletion" do
    { user: :belongs_to, activity_oshis: :has_many, oshis: :has_many }.each do |name, macro|
      association = described_class.reflect_on_association(name)
      expect(association.macro).to eq(macro)
      expect(association.options).not_to have_key(:dependent)
    end
    expect(described_class.reflect_on_association(:oshis).options[:through]).to eq(:activity_oshis)
  end

  [ :user, :occurred_on, :title, :activity_type ].each do |attribute|
    it "requires #{attribute}" do
      expect(build(:activity, attribute => nil)).not_to be_valid
    end
  end

  [ "", " " ].each do |value|
    it "rejects a blank title #{value.inspect}" do
      expect(build(:activity, title: value)).not_to be_valid
    end
  end

  it "accepts 255 characters for title and rejects 256" do
    expect(build(:activity, title: "あ" * 255)).to be_valid
    expect(build(:activity, title: "あ" * 256)).not_to be_valid
  end

  [ "ライブ・イベント", "配信視聴", "グッズ購入", "メディア視聴", "その他" ].each do |value|
    it "persists the specified activity type #{value} as a string" do
      activity = create(:activity, activity_type: value)
      expect(activity.reload.activity_type).to eq(value)
      expect(activity.activity_type_before_type_cast).to eq(value)
    end
  end

  [ "", " ", "unknown", "あ" * 51 ].each do |value|
    it "rejects activity_type=#{value.inspect}" do
      expect(build(:activity, activity_type: value)).not_to be_valid
    end
  end

  it "allows an optional place up to 255 characters" do
    [ nil, "", "あ" * 255 ].each do |value|
      expect(build(:activity, place: value)).to be_valid
    end
    expect(build(:activity, place: "あ" * 256)).not_to be_valid
  end

  it "persists an optional memo without a custom length limit" do
    [ nil, "あ" * 10_000 ].each do |value|
      expect(create(:activity, memo: value).reload.memo).to eq(value)
    end
  end

  it "persists future dates without a custom date range restriction" do
    date = Date.current + 365
    expect(create(:activity, occurred_on: date).reload.occurred_on).to eq(date)
  end

  it "rejects invalid dates" do
    expect(build(:activity, occurred_on: "invalid")).not_to be_valid
    expect(build(:activity, occurred_on: "2026-02-30")).not_to be_valid
  end

  [ nil, 0, 1, 1000, 10_000 ].each do |value|
    it "preserves amount=#{value.inspect}, including the distinction between nil and zero" do
      expect(create(:activity, amount: value).reload.amount).to eq(value)
    end
  end

  [ -1, -1000, 10.5, "10.5", "abc" ].each do |value|
    it "rejects amount=#{value.inspect} before integer casting hides invalid input" do
      expect(build(:activity, amount: value)).not_to be_valid
    end
  end

  it "requires at least one link, including unsaved links" do
    expect(build(:activity, :without_oshis)).not_to be_valid
    expect(build(:activity)).to be_valid
    expect(build(:activity, :multiple_oshis)).to be_valid
  end

  it "rejects saving when all links are marked for destruction" do
    activity = create(:activity, :multiple_oshis)
    activity.activity_oshis.each(&:mark_for_destruction)
    expect(activity).not_to be_valid
    expect { activity.save! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(activity.reload.activity_oshis.count).to eq(2)
  end

  it "allows saving when a link remains after removing a marked link" do
    activity = create(:activity, :multiple_oshis)
    activity.activity_oshis.first.mark_for_destruction
    activity.save!
    expect(activity.reload.activity_oshis.count).to eq(1)
  end

  it "does not accept a link without an oshi as a valid activity" do
    activity = build(:activity, :without_oshis)
    activity.activity_oshis.build
    expect(activity).not_to be_valid
  end

  describe "database constraints" do
    [ :user_id, :occurred_on, :title, :activity_type ].each do |attribute|
      it "rejects NULL #{attribute} without validation" do
        activity = create(:activity)
        expect do
          described_class.transaction(requires_new: true) { activity.update_columns(attribute => nil) }
        end.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    it "enforces the user foreign key" do
      activity = create(:activity)
      expect do
        described_class.transaction(requires_new: true) do
          activity.update_columns(user_id: User.maximum(:id).to_i + 1)
        end
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "has only the specified composite nonunique index" do
      indexes = described_class.connection.indexes("activities")
      expect(indexes.map(&:columns)).to eq([ [ "user_id", "occurred_on" ] ])
      expect(indexes.first.unique).to be(false)
    end

    it "uses the specified column types, limits, optional values, and no amount default" do
      columns = described_class.columns_hash
      expect(columns.fetch("occurred_on").type).to eq(:date)
      expect(columns.fetch("title").limit).to eq(255)
      expect(columns.fetch("activity_type").limit).to eq(50)
      expect(columns.fetch("place").limit).to eq(255)
      expect(columns.fetch("amount").type).to eq(:integer)
      expect(columns.fetch("amount").default).to be_nil
      expect(columns.fetch("memo").type).to eq(:text)
      [ "place", "amount", "memo" ].each { |name| expect(columns.fetch(name).null).to be(true) }
      [ "id", "created_at", "updated_at" ].each { |name| expect(columns.fetch(name).null).to be(false) }
      expect(described_class.connection.check_constraints("activities")).to be_empty
    end
  end
end
