class CreateCools < ActiveRecord::Migration[8.1]
  def change
    create_table :cools do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.timestamps

      t.index [:user_id, :topic_id], unique: true
    end

    add_column :topics, :cools_count, :integer, default: 0, null: false
  end
end
