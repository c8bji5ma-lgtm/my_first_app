class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.date :occurred_on, null: false
      t.string :title, limit: 255, null: false
      t.string :activity_type, limit: 50, null: false
      t.string :place, limit: 255
      t.integer :amount
      t.text :memo

      t.timestamps null: false
    end

    add_index :activities, [ :user_id, :occurred_on ]
  end
end
