class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.references :node, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :views_count, default: 0, null: false
      t.datetime :last_reply_at
      t.integer :last_reply_user_id

      t.timestamps
    end

    add_index :topics, [:node_id, :updated_at]
    add_index :topics, [:user_id, :created_at]
  end
end
