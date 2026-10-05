require "rails_helper"

RSpec.describe "Test infrastructure" do
  it "boots Rails in the test environment and connects to PostgreSQL" do
    expect(Rails.env).to eq("test")

    ActiveRecord::Base.connection_pool.with_connection do |connection|
      expect(connection.adapter_name).to eq("PostgreSQL")
      expect(connection.select_value("SELECT 1")).to eq(1)
      expect(connection.select_value("SELECT current_database()")).to eq(
        ActiveRecord::Base.connection_db_config.database
      )
    end
  end
end
