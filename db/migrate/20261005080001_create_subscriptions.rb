class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, limit: 255, null: false
      t.integer :amount, null: false
      t.string :billing_cycle, limit: 20, null: false
      t.date :started_on
      t.date :ended_on

      t.timestamps null: false
    end
  end
end
