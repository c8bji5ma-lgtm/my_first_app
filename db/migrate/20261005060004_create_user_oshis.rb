class CreateUserOshis < ActiveRecord::Migration[8.1]
  def change
    create_table :user_oshis do |t|
      t.references :user, null: false, foreign_key: true
      t.references :oshi, null: false, foreign_key: true
      t.string :started_period, limit: 7
      t.string :ended_period, limit: 7

      t.timestamps null: false
    end

    add_index :user_oshis, [ :user_id, :oshi_id ], unique: true
  end
end
