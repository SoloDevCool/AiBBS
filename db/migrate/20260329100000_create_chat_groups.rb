class CreateChatGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_groups do |t|
      t.string :name, null: false
      t.string :category
      t.integer :members_count, default: 0, null: false
      t.text :description
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
  end
end
