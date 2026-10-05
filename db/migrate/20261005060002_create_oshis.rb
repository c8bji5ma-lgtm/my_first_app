class CreateOshis < ActiveRecord::Migration[8.1]
  def change
    create_table :oshis do |t|
      t.string :name, limit: 255, null: false
      t.string :oshi_type, limit: 50, null: false
      t.string :affiliation, limit: 255
      t.string :status, limit: 20, null: false, default: "pending"
      t.references :created_by_user, foreign_key: { to_table: :users }

      t.timestamps null: false
    end

    add_index :oshis, :name
  end
end
