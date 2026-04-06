class AddKindToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :kind, :string, null: false, default: "interest"
  end
end
