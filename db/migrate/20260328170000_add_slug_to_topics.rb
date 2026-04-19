class AddSlugToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :slug, :string
    add_index :topics, :slug
  end
end
