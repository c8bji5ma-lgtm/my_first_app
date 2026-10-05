class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name, limit: 50, null: false
      t.text :introduction

      t.timestamps null: false
    end
  end
end
