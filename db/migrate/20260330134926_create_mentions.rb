class CreateMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :mentions do |t|
      t.references :topic, null: true, foreign_key: true
      t.references :comment, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :mentions, [:topic_id, :user_id]
    add_index :mentions, [:comment_id, :user_id]
  end
end
