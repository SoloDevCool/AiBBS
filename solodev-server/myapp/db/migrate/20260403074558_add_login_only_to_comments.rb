class AddLoginOnlyToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :login_only, :boolean, default: false, null: false
  end
end
