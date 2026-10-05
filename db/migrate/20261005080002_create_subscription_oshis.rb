class CreateSubscriptionOshis < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_oshis do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :oshi, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :subscription_oshis, [ :subscription_id, :oshi_id ], unique: true
  end
end
