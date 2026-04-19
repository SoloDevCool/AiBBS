class AddProfilePublicToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_public, :boolean, default: true, null: false
  end
end
