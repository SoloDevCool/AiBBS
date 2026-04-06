class CreateNodeFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :node_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true

      t.timestamps
    end
    add_index :node_follows, [:user_id, :node_id], unique: true
  end
end
