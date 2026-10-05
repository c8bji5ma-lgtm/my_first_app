class CreateActivityOshis < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_oshis do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :oshi, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :activity_oshis, [ :activity_id, :oshi_id ], unique: true
  end
end
