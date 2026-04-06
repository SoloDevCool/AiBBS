class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string
  end
end
