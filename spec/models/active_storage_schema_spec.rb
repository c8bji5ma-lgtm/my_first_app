require "rails_helper"

RSpec.describe "Active Storage schema", type: :model do
  let(:connection) { ActiveRecord::Base.connection }

  it "has the three standard tables" do
    %w[active_storage_blobs active_storage_attachments active_storage_variant_records].each do |table|
      expect(connection.table_exists?(table)).to be(true)
    end
  end

  it "has the standard unique indexes" do
    {
      "active_storage_blobs" => %w[key],
      "active_storage_attachments" => %w[record_type record_id name blob_id],
      "active_storage_variant_records" => %w[blob_id variation_digest]
    }.each do |table, columns|
      expect(connection.indexes(table).any? { |index| index.unique && index.columns == columns }).to be(true)
    end
  end

  it "has blob foreign keys and no custom polymorphic owner foreign key" do
    %w[active_storage_attachments active_storage_variant_records].each do |table|
      keys = connection.foreign_keys(table)
      expect(keys.size).to eq(1)
      expect(keys.first.to_table).to eq("active_storage_blobs")
      expect(keys.first.column).to eq("blob_id")
    end
  end
end
