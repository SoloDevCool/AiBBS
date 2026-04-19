class AddIsRepostAndSourceUrlToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :is_repost, :boolean, default: false, null: false
    add_column :topics, :source_url, :string
  end
end
