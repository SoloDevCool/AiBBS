class CreateTips < ActiveRecord::Migration[8.1]
  def change
    create_table :tips do |t|
      t.bigint :topic_id, null: false
      t.bigint :from_user_id, null: false
      t.bigint :to_user_id, null: false
      t.bigint :comment_id, null: false
      t.integer :amount, null: false
      t.timestamps
    end
    add_index :tips, :topic_id
    add_index :tips, :from_user_id
    add_index :tips, :to_user_id
    add_index :tips, :comment_id
    add_foreign_key :tips, :topics
    add_foreign_key :tips, :users, column: :from_user_id
    add_foreign_key :tips, :users, column: :to_user_id
    add_foreign_key :tips, :comments
  end
end
