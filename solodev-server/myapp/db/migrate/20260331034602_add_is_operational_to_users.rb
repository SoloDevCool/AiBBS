class AddIsOperationalToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_operational, :boolean, default: false, null: false
  end
end
