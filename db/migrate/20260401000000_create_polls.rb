class CreatePolls < ActiveRecord::Migration[8.1]
  def change
    create_table :polls do |t|
      t.references :topic, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.boolean :closed, default: false, null: false
      t.datetime :closed_at
      t.timestamps
    end

    create_table :poll_options do |t|
      t.references :poll, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :votes_count, default: 0, null: false
      t.integer :sort_order, default: 0, null: false
      t.timestamps
    end

    create_table :votes do |t|
      t.references :poll_option, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps

      t.index [:user_id, :poll_option_id], unique: true
      t.index "poll_option_id, user_id", unique: true, name: "index_votes_on_poll_option_id_and_user_id"
    end

    add_index :polls, :topic_id, unique: true, name: "index_polls_on_topic_id_unique"
  end
end
