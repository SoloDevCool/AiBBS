class CreateCommentCools < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_cools do |t|
      t.bigint :comment_id, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end
    add_index :comment_cools, [:user_id, :comment_id], unique: true, name: "index_comment_cools_on_user_id_and_comment_id"
    add_index :comment_cools, :comment_id
    add_index :comment_cools, :user_id
    add_foreign_key :comment_cools, :comments
    add_foreign_key :comment_cools, :users
  end
end
