class CreateOshiAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :oshi_aliases do |t|
      t.references :oshi, null: false, foreign_key: true
      t.string :alias_name, limit: 255, null: false

      t.timestamps null: false
    end

    add_index :oshi_aliases, :alias_name
    add_index :oshi_aliases, [ :oshi_id, :alias_name ], unique: true
  end
end
