class AddPinnedToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :pinned, :boolean, default: false, null: false
    add_column :topics, :pinned_at, :datetime
    add_index :topics, :pinned, where: "pinned = true"
  end
end
