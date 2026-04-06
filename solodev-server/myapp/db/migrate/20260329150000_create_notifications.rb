class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint :user_id, null: false
      t.bigint :actor_id, null: false
      t.references :notifiable, polymorphic: true, null: false
      t.string :notify_type, null: false
      t.boolean :read, default: false, null: false
      t.datetime :created_at, null: false

      t.index [:user_id, :created_at]
      t.index [:user_id, :read]
      t.index [:actor_id, :notify_type, :notifiable_id, :notifiable_type], name: "index_notifications_unique", unique: true
    end

    add_column :users, :unread_notifications_count, :integer, default: 0, null: false
  end
end
