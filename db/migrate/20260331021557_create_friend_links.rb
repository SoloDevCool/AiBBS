class CreateFriendLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :friend_links do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :description
      t.string :logo
      t.integer :sort_order, default: 0
      t.boolean :is_active, default: true

      t.timestamps
    end
  end
end
