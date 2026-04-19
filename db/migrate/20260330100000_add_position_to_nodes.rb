class AddPositionToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :position, :integer, default: 0, null: false
    add_index :nodes, :position
  end
end
